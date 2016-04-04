# CrashSymbolicator
Small and handy script in Ruby to symbolicate .crash logs for iOS

# Usage

Place your .crash log into same directory with your .dSYM and .app files.

Then run:

```
./symbolicate.rb path-to-your-crash-file.crash
```

Alternatively you can use next code in ruby:

```
symbolicator = CrashSymbolicator.new(path_to_dsym)
symbolicator.symbolicte(path_to_crash, output_path)
```
