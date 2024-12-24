
# VideoToolbox Uncompressed Textures Bug

VideoToolbox/CoreVideo currently has a bug, originating on visionOS 2.0/iOS 18, which causes intermediate and final render targets on color conversions to be uncompressed, resulting in a 10x-ing of GPU bandwidth which can overheat chips on streams as small as 4K, especially with multiple streams at high FPS.

## Variant A

10-bit (HDR) HEVC requires the use of private `MTLPixelFormat`s in order to decode without hitting this bug, because any format conversion will trigger the uncompressed render targets. In the sample, this format conversion is to `kCVPixelFormatType_420YpCbCr10BiPlanarFullRange`/`kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange`. There are compressed `kCVPixelFormatType`s that can only be decoded by private `MTLPixelFormat`s used in Webkit.

## Variant B

**Any** identity format conversion (format conversion to the same format that the video stream is already in) will also result in a redudant conversion to an uncompressed render target, 10x-ing the GPU bandwidth for no appearent reason. In the sample this is done with `kCVPixelFormatType_420YpCbCr10PackedBiPlanarFullRange`/`kCVPixelFormatType_420YpCbCr10PackedBiPlanarVideoRange`

## Hardware variance

This bug does NOT trigger on the following hardware (not a conclusive list)

 - visionOS simulator on M1 Max on macOS versions: 15.2
 
 This bug continues to trigger on the following hardware
 
 - M2 Apple Vision Pro on visionOS versions: 2.0, 2.1, 2.2
