// Mira chat with the server-side free-limit gate (Prompt M6 §1).
// - JWT verified here (deploy WITH JWT verification).
// - Conversation origin is read from the DB, never from the request body.
// - consume_quota() runs BEFORE the LLM call; HTTP 402 {code:'limit'} when blocked.
// - SOS conversations: never counted, never blocked, crisis-safe system prompt.
// - LLM failure → refund_message() so a failed reply never costs a message.
// Secrets: ANTHROPIC_API_KEY, optional HELPLINE_TR / HELPLINE_US / EMERGENCY_TR / EMERGENCY_US.
// UNTESTED: see README.md.
import Anthropic from "npm:@anthropic-ai/sdk";
import { admin } from "../_shared/revenuecat.ts";

const MODEL = "claude-opus-5-5";
const MAX_INPUT_CHARS = 4000;
const HISTORY_LIMIT = 20;

const anthropic = new Anthropic(); // reads ANTHROPIC_API_KEY

const COACH_SYSTEM_PROMPT = `You are Mira, the warm, steady breakup-recovery coach inside the MyEx app.
You help the user through a breakup: no-contact, urges to text the ex, rumination, self-worth, and small daily steps.
Be brief (2-5 short sentences), kind and concrete. Ask one gentle question at a time.
Never encourage contacting the ex, checking their social media, or getting back together as a quick fix.
You are an AI coach, not a therapist or a medical service, and you never diagnose. If the user mentions
self-harm, harm to others, abuse or a crisis, stop coaching, say you're concerned, and urge them to contact
local emergency services or a crisis line now.
Reply in the user's language (English or Turkish; Turkish uses informal "sen").`;

function sosSystemPrompt(locale: string): string {
  const tr = locale === "tr";
  const emergency = Deno.env.get(tr ? "EMERGENCY_TR" : "EMERGENCY_US") ?? (tr ? "112" : "911");
  const helpline = Deno.env.get(tr ? "HELPLINE_TR" : "HELPLINE_US") ?? "";
  return `You are Mira in SOS mode inside the MyEx app. The user opened SOS: they may be in acute distress or about
to text their ex. Your only goals are safety and getting through the next 10 minutes.
- Ground first: slow breathing, naming 5 things they can see, feet on the floor. Short sentences.
- No romance or relationship advice, no analysis of the ex, no homework.
- If there is ANY sign of risk (self-harm, suicide, harm to others, abuse, feeling unsafe), say clearly that
  they deserve real human help right now and give: emergency ${emergency}${helpline ? `, crisis line ${helpline}` : ""}.
- Never mention subscriptions, coins, limits or app features.
- You are an AI, not a therapist. Reply in the user's language (English or Turkish, informal "sen").`;
}

function refusalReply(locale: string): string {
  return locale === "tr"
    ? "Buradayım. Şu an bunu birlikte konuşamıyorum, ama kendini güvende hissetmiyorsan lütfen hemen gerçek bir insana ulaş."
    : "I'm here. I can't help with that one, but if you don't feel safe, please reach a real person right now.";
}

const json = (body: unknown, status = 200) => Response.json(body, { status });

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("method not allowed", { status: 405 });

  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  const { data: { user } } = await admin.auth.getUser(token);
  if (!user) return new Response("unauthorized", { status: 401 });

  // deno-lint-ignore no-explicit-any
  let body: any;
  try {
    body = await req.json();
  } catch {
    return new Response("bad json", { status: 400 });
  }
  const conversationId = body?.conversation_id;
  const text = typeof body?.message === "string" ? body.message.trim() : "";
  if (typeof conversationId !== "string" || !text || text.length > MAX_INPUT_CHARS) {
    return new Response("bad request", { status: 400 });
  }

  // Origin from the DB only. A body claiming "sos" has no effect.
  const { data: conv } = await admin
    .from("conversations")
    .select("id, origin, user_id")
    .eq("id", conversationId)
    .maybeSingle();
  if (!conv || conv.user_id !== user.id) return new Response("not found", { status: 404 });

  const { data: q, error: qErr } = await admin.rpc("consume_quota", {
    p_uid: user.id,
    p_kind: "message",
    p_origin: conv.origin,
  });
  if (qErr) return new Response("quota error", { status: 500 });
  if (!q.allowed) return json({ code: "limit", resets_at: q.resets_at }, 402);

  const { data: profile } = await admin.from("profiles").select("locale").eq("id", user.id).maybeSingle();
  const locale: string = profile?.locale ?? "en";

  try {
    const { data: rows, error: hErr } = await admin
      .from("messages")
      .select("role, content")
      .eq("conversation_id", conv.id)
      .order("created_at", { ascending: false })
      .limit(HISTORY_LIMIT);
    if (hErr) throw hErr;
    const history = (rows ?? []).reverse() as Array<{ role: "user" | "assistant"; content: string }>;
    while (history.length && history[0].role !== "user") history.shift(); // must start with user

    // VERIFY against the installed SDK typings: server-side refusal fallbacks
    // (beta) + effort. Chat replies are short; low effort keeps latency down.
    const response = await anthropic.beta.messages.create({
      model: MODEL,
      max_tokens: 16000,
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
      output_config: { effort: "low" },
      cache_control: { type: "ephemeral" },
      system: conv.origin === "sos" ? sosSystemPrompt(locale) : COACH_SYSTEM_PROMPT,
      messages: [
        ...history.map((m) => ({ role: m.role, content: m.content })),
        { role: "user" as const, content: text },
      ],
    // deno-lint-ignore no-explicit-any
    } as any);

    let reply = "";
    if (response.stop_reason === "refusal") {
      reply = refusalReply(locale);
    } else {
      for (const block of response.content) {
        if (block.type === "text") reply += block.text;
      }
      reply = reply.trim();
    }
    if (!reply) throw new Error(`empty reply (stop_reason=${response.stop_reason})`);

    // Store the pair only after success, so history always alternates.
    const { error: insErr } = await admin.from("messages").insert([
      { conversation_id: conv.id, user_id: user.id, role: "user", content: text },
      { conversation_id: conv.id, user_id: user.id, role: "assistant", content: reply },
    ]);
    if (insErr) console.error("message insert failed", conv.id, insErr.message);

    return json({ reply, quota: q });
  } catch (e) {
    if (e instanceof Anthropic.APIError) {
      console.error("LLM error", e.status, e.message);
    } else {
      console.error("mira-chat failed", String(e));
    }
    if (q.counted) await admin.rpc("refund_message", { p_uid: user.id, p_via: q.via });
    return new Response("mira unavailable", { status: 502 });
  }
});
