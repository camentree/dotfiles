import scala.concurrent.duration._

// The thin client leaves one server per checkout running until this elapses (default 7 days), so
// removed worktrees strand a 5G JVM. A fresh server boots in ~30s; on-disk zinc state is kept.
Global / serverIdleTimeout := Some(1.hour)
