# Installation

Follow these steps to install and set up `sqlitec` in your Dart or Flutter project.

---

## 1. Add Dependencies

Add `sqlitec` and `build_runner` to your `dev_dependencies` in `pubspec.yaml`.  

**Example (`pubspec.yaml`):**
```yaml
dev_dependencies:
  sqlitec: ^0.1.0
  build_runner: ^2.0.0
```

See [example/pubspec.yaml](../../example/pubspec.yaml) or [pubspec.yaml](../../pubspec.yaml) for reference.

---

**Tip:**  
Whenever you update your `.sql` files, re-run the build command to update the generated Dart code.