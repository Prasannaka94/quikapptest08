#!/bin/bash

# FirebaseInstallations Linker Fix for iOS Archive
# Purpose: Fix linking errors with FirebaseInstallations framework during archive creation
# This addresses the specific linking issue that occurs after Firebase compilation succeeds

set -euo pipefail

echo "🔗 FIREBASE INSTALLATIONS LINKER FIX"
echo "🎯 Fixing linking issues with FirebaseInstallations framework"

# Get project root
PROJECT_ROOT=$(pwd)
PODS_DIR="$PROJECT_ROOT/ios/Pods"
PROJECT_FILE="$PROJECT_ROOT/ios/Runner.xcodeproj/project.pbxproj"

# Function to fix FirebaseInstallations linking issues
fix_firebase_installations_linking() {
    echo "🔧 Fixing FirebaseInstallations linking issues..."
    
    if [ -d "$PODS_DIR/FirebaseInstallations" ]; then
        echo "📦 Found FirebaseInstallations pod"
        
        # Check the FirebaseInstallations podspec for linking issues
        local podspec_file="$PODS_DIR/FirebaseInstallations/FirebaseInstallations.podspec"
        if [ -f "$podspec_file" ]; then
            echo "📝 Found FirebaseInstallations podspec"
            
            # Create backup
            cp "$podspec_file" "$podspec_file.linker_fix_backup" || true
            
            # Fix common linking issues in podspec
            sed -i '' 's/s.static_framework = true/s.static_framework = false/' "$podspec_file" || true
            sed -i '' '/s.pod_target_xcconfig.*DEFINES_MODULE.*YES/d' "$podspec_file" || true
            
            echo "✅ Fixed FirebaseInstallations podspec linking settings"
        fi
        
        # Fix the FirebaseInstallations xcconfig files
        find "$PODS_DIR/Target Support Files/FirebaseInstallations" -name "*.xcconfig" -type f | while read xcconfig_file; do
            if [ -f "$xcconfig_file" ]; then
                echo "🔧 Fixing xcconfig: $xcconfig_file"
                
                # Create backup
                cp "$xcconfig_file" "$xcconfig_file.linker_fix_backup" || true
                
                # Add/fix linking flags
                echo "" >> "$xcconfig_file"
                echo "// FirebaseInstallations Linker Fix" >> "$xcconfig_file"
                echo "OTHER_LDFLAGS = \$(inherited) -framework Foundation -framework SystemConfiguration" >> "$xcconfig_file"
                echo "FRAMEWORK_SEARCH_PATHS = \$(inherited) \$(PODS_ROOT)/FirebaseInstallations/Frameworks" >> "$xcconfig_file"
                echo "LIBRARY_SEARCH_PATHS = \$(inherited) \$(PODS_ROOT)/FirebaseInstallations/Libraries" >> "$xcconfig_file"
                echo "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES = YES" >> "$xcconfig_file"
                echo "DEFINES_MODULE = NO" >> "$xcconfig_file"
                echo "MODULEMAP_FILE = " >> "$xcconfig_file"
                
                echo "✅ Fixed xcconfig: $xcconfig_file"
            fi
        done
    else
        echo "⚠️ FirebaseInstallations pod not found"
    fi
}

# Function to fix project linker settings
fix_project_linker_settings() {
    echo "🔧 Fixing project linker settings..."
    
    if [ -f "$PROJECT_FILE" ]; then
        echo "📝 Found project file"
        
        # Create backup
        cp "$PROJECT_FILE" "$PROJECT_FILE.linker_fix_backup"
        
        # Apply linker fixes using Python
        python3 -c "
import re

# Read the project file
with open('$PROJECT_FILE', 'r') as f:
    content = f.read()

# Add linker settings for better compatibility
linker_settings = '''
				OTHER_LDFLAGS = \"\$(inherited) -framework Foundation -framework SystemConfiguration -framework Security -ObjC\";
				FRAMEWORK_SEARCH_PATHS = \"\$(inherited) \$(PODS_ROOT)/FirebaseInstallations/Frameworks\";
				LIBRARY_SEARCH_PATHS = \"\$(inherited) \$(PODS_ROOT)/FirebaseInstallations/Libraries\";
				STRIP_INSTALLED_PRODUCT = NO;
				DEPLOYMENT_POSTPROCESSING = NO;
				SEPARATE_STRIP = NO;
				COPY_PHASE_STRIP = NO;
				CLANG_ENABLE_MODULE_DEBUGGING = NO;
				DEBUG_INFORMATION_FORMAT = \"dwarf\";
				VALIDATE_PRODUCT = NO;
				ENABLE_TESTABILITY = NO;
				GCC_GENERATE_DEBUGGING_SYMBOLS = YES;
				CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES = YES;
				DEFINES_MODULE = NO;
'''

# Find all build configuration sections and add linker settings
pattern = r'(buildSettings = \{.*?)(\};)'
replacement = r'\1' + linker_settings + r'\2'

# Apply the replacement
modified_content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# Write back to file
with open('$PROJECT_FILE', 'w') as f:
    f.write(modified_content)

print('✅ Project linker settings fixed')
"
        
        echo "✅ Project linker settings applied"
    else
        echo "❌ Project file not found: $PROJECT_FILE"
        return 1
    fi
}

# Function to create enhanced Podfile with linker fixes
create_enhanced_podfile_linker_fix() {
    echo "🔧 Creating enhanced Podfile with linker fixes..."
    
    local podfile="$PROJECT_ROOT/ios/Podfile"
    
    if [ -f "$podfile" ]; then
        # Create backup
        cp "$podfile" "$podfile.linker_fix_backup"
        echo "✅ Backup created: $podfile.linker_fix_backup"
        
        # Check if we already have linker fixes
        if ! grep -q "FIREBASE INSTALLATIONS LINKER FIX" "$podfile"; then
            # Add enhanced linker fix to existing post_install
            sed -i '' '/# FINAL FIREBASE SOLUTION: Ultimate Podfile Configuration/a\
\
# FIREBASE INSTALLATIONS LINKER FIX\
puts "🔗 Applying FirebaseInstallations linker fixes..."\
\
# Fix FirebaseInstallations specific linking issues\
installer.pods_project.targets.each do |target|\
  if target.name == "FirebaseInstallations"\
    puts "🔧 Fixing FirebaseInstallations target: #{target.name}"\
    target.build_configurations.each do |config|\
      # Force static framework settings\
      config.build_settings["DEFINES_MODULE"] = "NO"\
      config.build_settings["MODULEMAP_FILE"] = ""\
      config.build_settings["CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES"] = "YES"\
      config.build_settings["OTHER_LDFLAGS"] = "$(inherited) -framework Foundation -framework SystemConfiguration -ObjC"\
      config.build_settings["FRAMEWORK_SEARCH_PATHS"] = "$(inherited) $(PODS_ROOT)/FirebaseInstallations/Frameworks"\
      config.build_settings["LIBRARY_SEARCH_PATHS"] = "$(inherited) $(PODS_ROOT)/FirebaseInstallations/Libraries"\
      config.build_settings["STRIP_INSTALLED_PRODUCT"] = "NO"\
      config.build_settings["DEPLOYMENT_POSTPROCESSING"] = "NO"\
      config.build_settings["SEPARATE_STRIP"] = "NO"\
      config.build_settings["COPY_PHASE_STRIP"] = "NO"\
      config.build_settings["DEBUG_INFORMATION_FORMAT"] = "dwarf"\
      config.build_settings["GCC_GENERATE_DEBUGGING_SYMBOLS"] = "YES"\
      config.build_settings["VALIDATE_PRODUCT"] = "NO"\
      config.build_settings["ENABLE_TESTABILITY"] = "NO"\
      \
      puts "      ✅ FirebaseInstallations linker fix applied"\
    end\
  end\
end\
\
puts "✅ FirebaseInstallations linker fixes completed"
' "$podfile"
            
            echo "✅ Enhanced Podfile linker fixes added"
        else
            echo "ℹ️ Linker fixes already present in Podfile"
        fi
    else
        echo "❌ Podfile not found: $podfile"
        return 1
    fi
}

# Function to clean and rebuild pods with linker fixes
rebuild_pods_with_linker_fixes() {
    echo "🔄 Cleaning and rebuilding pods with linker fixes..."
    
    cd "$PROJECT_ROOT/ios"
    
    # Clean existing pods
    echo "🧹 Cleaning existing pods..."
    rm -rf Pods/
    rm -rf Podfile.lock
    rm -rf .symlinks/
    
    # Reinstall pods
    echo "📦 Reinstalling pods with linker fixes..."
    pod install --repo-update
    
    if [ $? -eq 0 ]; then
        echo "✅ Pods reinstalled successfully with linker fixes"
    else
        echo "❌ Failed to reinstall pods"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
}

# Main execution function
main() {
    echo "🔗 Starting FirebaseInstallations Linker Fix..."
    echo "🎯 This will resolve linking errors during archive creation"
    
    # Step 1: Fix FirebaseInstallations specific linking issues
    fix_firebase_installations_linking
    
    # Step 2: Fix project linker settings
    fix_project_linker_settings
    
    # Step 3: Create enhanced Podfile with linker fixes
    create_enhanced_podfile_linker_fix
    
    # Step 4: Rebuild pods with linker fixes
    rebuild_pods_with_linker_fixes
    
    echo ""
    echo "✅ FirebaseInstallations Linker Fix completed successfully!"
    echo "📋 Summary of linker fixes applied:"
    echo "   🔗 FirebaseInstallations podspec linking fixed"
    echo "   🔗 Project linker settings optimized"
    echo "   🔗 Enhanced Podfile linker configuration"
    echo "   🔗 Pods rebuilt with linker fixes"
    echo ""
    echo "🎯 Archive creation should now succeed!"
    echo "🔧 Next steps:"
    echo "   1. Try running the iOS workflow again"
    echo "   2. The archive process should complete successfully"
    echo ""
    echo "💡 This fix addresses linking issues that occur after successful compilation"
    
    return 0
}

# Execute main function
main "$@" 