Pod::Spec.new do |spec|
  spec.name          = 'weebi_barcode_scanner'
  spec.version       = '0.0.1'
  spec.license       = { :file => '../LICENSE' }
  spec.homepage      = 'https://github.com/weebi-com/weebi_barcode_scanner'
  spec.authors       = { 'Weebi' => 'contact@weebi.com' }
  spec.summary       = 'Advanced barcode scanner using YOLO-based detection with Rust backend'
  spec.description   = <<-DESC
Advanced barcode scanner with YOLO-based detection, featuring high accuracy barcode recognition 
for damaged and low-quality barcodes using a Rust-powered backend.
                       DESC

  spec.source        = { :path => '.' }
  spec.source_files  = 'Classes/**/*'
  spec.dependency 'FlutterMacOS'

  spec.platform = :osx, '10.11'
  spec.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES'
  }
  spec.swift_version = '5.0'

  # Native library configuration - include all variants
  spec.vendored_libraries = 'Frameworks/librust_barcode_lib.dylib'
  
  # Ensure the universal binary is created
  # NOTE: Do not vendor a dylib at install time; it may not exist in the pod sandbox yet.
  # spec.vendored_libraries = 'Frameworks/librust_barcode_lib.dylib'

  # Ensure the universal binary is created
  spec.prepare_command = <<-CMD
    echo "Creating universal binary for Rust barcode library..."

    # Check if we have both architecture-specific libraries
    if [ -f "Frameworks/librust_barcode_lib_x86_64.dylib" ] && [ -f "Frameworks/librust_barcode_lib_aarch64.dylib" ]; then
      echo "Creating universal binary from x86_64 and aarch64 libraries..."
      lipo -create "Frameworks/librust_barcode_lib_x86_64.dylib" "Frameworks/librust_barcode_lib_aarch64.dylib" -output "Frameworks/librust_barcode_lib.dylib"
      echo "Universal binary created successfully"
    elif [ -f "Frameworks/librust_barcode_lib_x86_64.dylib" ]; then
      echo "Using x86_64 library as universal binary..."
      cp "Frameworks/librust_barcode_lib_x86_64.dylib" "Frameworks/librust_barcode_lib.dylib"
    elif [ -f "Frameworks/librust_barcode_lib_aarch64.dylib" ]; then
      echo "Using aarch64 library as universal binary..."
      cp "Frameworks/librust_barcode_lib_aarch64.dylib" "Frameworks/librust_barcode_lib.dylib"
    else
      echo "ERROR: No Rust libraries found in Frameworks directory!"
      exit 1
    fi

    # Fix the install name to use @rpath
    if [ -f "Frameworks/librust_barcode_lib.dylib" ]; then
      echo "Fixing install name for universal binary..."
      install_name_tool -id "@rpath/librust_barcode_lib.dylib" "Frameworks/librust_barcode_lib.dylib"
      echo "Install name fixed successfully"
    fi
  CMD
  # IMPORTANT:
  # Do not perform arch merging at install-time. If needed, do it at build-time (script_phase) or in the app target.
 end