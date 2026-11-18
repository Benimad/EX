/// Where a Mira conversation was started. Stored server-side on
/// `conversations.origin` at creation. 'sos' conversations never count toward
/// any limit, use the crisis-safe prompt, and never show monetization UI
/// (M0 hard rule 1).
enum ChatOrigin {
  normal,
  sos;

  String get wire => name;
}
