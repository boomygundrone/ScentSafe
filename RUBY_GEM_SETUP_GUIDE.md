# Ruby and Gem Setup Guide for iOS Development

## Overview
This guide explains how to set up Ruby and Gems properly for iOS development without permission errors. This is particularly useful when you encounter errors like:
```
Gem::FilePermissionError
You don't have write permissions for /Library/Ruby/Gems/2.6.0 directory.
```

## Quick Setup

### Step 1: Set GEM_HOME Environment Variable

Add the following to your `~/.zshrc` file:

```bash
export GEM_HOME="$HOME/.gem"
```

**To add it automatically:**
```bash
echo 'export GEM_HOME="$HOME/.gem"' >> ~/.zshrc
```

### Step 2: Reload Shell Configuration

After adding to `~/.zshrc`, reload your shell configuration:

```bash
source ~/.zshrc
```

Or open a new terminal window.

### Step 3: Verify GEM_HOME is Set

```bash
echo $GEM_HOME
```

Expected output:
```
/Users/your-username/.gem
```

### Step 4: Add Gem Bin Directory to PATH

Add the gem bin directory to your PATH in `~/.zshrc`:

```bash
export PATH="$GEM_HOME/bin:$PATH"
```

**To add it automatically:**
```bash
echo 'export PATH="$GEM_HOME/bin:$PATH"' >> ~/.zshrc
```

### Step 5: Complete ~/.zshrc Setup

Your `~/.zshrc` should now include these lines:

```bash
# Gem configuration for user-space installation
export GEM_HOME="$HOME/.gem"
export PATH="$GEM_HOME/bin:$PATH"
```

### Step 6: Reload and Verify

```bash
# Reload shell configuration
source ~/.zshrc

# Verify GEM_HOME
echo $GEM_HOME
# Should output: /Users/your-username/.gem

# Verify PATH includes gem bin
echo $PATH | grep gem
# Should show: /Users/your-username/.gem/bin:...

# Verify gem will install to correct location
gem env home
# Should output: /Users/your-username/.gem
```

## Installing Gems Without Sudo

Once GEM_HOME is configured, you can install gems without sudo:

```bash
# Install CocoaPods (compatible with Ruby 2.6+)
gem install cocoapods -v 1.14.3

# Verify installation
pod --version
```

## Complete Setup Script

Here's a complete script to set up everything:

```bash
#!/bin/bash

echo "🔧 Setting up Ruby and Gem configuration..."

# Add GEM_HOME to ~/.zshrc
if ! grep -q 'export GEM_HOME' ~/.zshrc; then
    echo 'export GEM_HOME="$HOME/.gem"' >> ~/.zshrc
    echo "✅ Added GEM_HOME to ~/.zshrc"
else
    echo "ℹ️  GEM_HOME already exists in ~/.zshrc"
fi

# Add gem bin to PATH in ~/.zshrc
if ! grep -q 'export PATH="$GEM_HOME/bin:$PATH"' ~/.zshrc; then
    echo 'export PATH="$GEM_HOME/bin:$PATH"' >> ~/.zshrc
    echo "✅ Added gem bin to PATH in ~/.zshrc"
else
    echo "ℹ️  gem bin already in PATH in ~/.zshrc"
fi

# Reload shell configuration
echo "🔄 Reloading shell configuration..."
source ~/.zshrc

# Verify setup
echo ""
echo "📊 Verification:"
echo "GEM_HOME: $GEM_HOME"
echo "Gem home: $(gem env home)"
echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Install CocoaPods: gem install cocoapods -v 1.14.3"
echo "2. Run iOS reset: ./reset_ios_build.sh --full"
```

Save this as `setup_ruby_gems.sh`, make it executable (`chmod +x setup_ruby_gems.sh`), and run it.

## Alternative: Using Homebrew Ruby

If you prefer to use a newer Ruby version via Homebrew:

```bash
# Install Ruby via Homebrew
brew install ruby

# Add Homebrew Ruby to PATH (add to ~/.zshrc)
echo 'export PATH="/usr/local/opt/ruby/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify Ruby version
ruby -v
# Should show Ruby 3.x.x

# Install CocoaPods (no sudo needed)
gem install cocoapods

# Verify installation
pod --version
```

## Troubleshooting

### Issue: gem command not found after setting GEM_HOME

**Solution:** Make sure to reload your shell configuration:
```bash
source ~/.zshrc
```

Or open a new terminal window.

### Issue: Gems still installing to system directory

**Solution:** Verify GEM_HOME is set correctly:
```bash
echo $GEM_HOME
gem env home
```

Both should show `/Users/your-username/.gem`

If not, check your `~/.zshrc` file:
```bash
cat ~/.zshrc | grep GEM_HOME
```

### Issue: Permission errors persist

**Solution:** Make sure you're not using sudo:
```bash
# Wrong (will cause permission errors)
sudo gem install cocoapods

# Correct (uses GEM_HOME)
gem install cocoapods
```

## Benefits of Using GEM_HOME

1. **No Sudo Required**: Install gems without sudo
2. **No Permission Errors**: Avoid `/Library/Ruby/Gems` permission issues
3. **User-Space Installation**: Gems are installed in your home directory
4. **Isolated Environment**: Separate from system Ruby gems
5. **Easy Cleanup**: Can easily remove `~/.gem` directory if needed

## Current Status

✅ **GEM_HOME has been configured** in your `~/.zshrc` file
✅ **GEM_HOME is set to**: `/Users/kimberlychan/.gem`

## Next Steps

1. **Reload your shell** (or open new terminal):
   ```bash
   source ~/.zshrc
   ```

2. **Install CocoaPods** (compatible with your Ruby 2.6.10):
   ```bash
   gem install cocoapods -v 1.14.3
   ```

3. **Verify installation**:
   ```bash
   pod --version
   ```

4. **Run iOS reset script**:
   ```bash
   cd scentsafe
   ./reset_ios_build.sh --full
   ```

## Additional Resources

- [RubyGems Documentation](https://guides.rubygems.org/)
- [CocoaPods Installation Guide](https://guides.cocoapods.org/using/getting-started.html)
- [Homebrew Ruby](https://github.com/Homebrew/homebrew-core/blob/master/Formula/ruby.rb)

---

**Last Updated:** 2026-01-12
**Project:** ScentSafe Flutter Application
**Ruby Version:** 2.6.10.210
**GEM_HOME:** /Users/kimberlychan/.gem
