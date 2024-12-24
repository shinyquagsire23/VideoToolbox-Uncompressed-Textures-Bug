//
//  VideoHandler.swift
//

import Foundation
import VideoToolbox
import AVKit

// We use the same MTLPixelFormats that WebKit does for 10-bit HEVC decoding.
// Also it's like a half a ms faster than decoding ourselves, yippee
let forceFastSecretTextureFormats = true

// FEEDBACK: LOOK HERE
let triggerDecompressedBugTypeA = true // Not using private MTLPixelFormats, how most developers would decode 10-bit HEVC
let triggerDecompressedBugTypeB = true // Silly bug, VideoToolbox will both do a superfluous format conversion, *and* the final buffer will be decompressed

let H264_NAL_TYPE_SPS = 7
let HEVC_NAL_TYPE_VPS = 32

//
// Non-conclusive list of interesting private Metal pixel formats
//
let MTLPixelFormatYCBCR8_420_2P: UInt = 500
let MTLPixelFormatYCBCR8_422_1P: UInt = 501
let MTLPixelFormatYCBCR8_422_2P: UInt = 502
let MTLPixelFormatYCBCR8_444_2P: UInt = 503
let MTLPixelFormatYCBCR10_444_1P: UInt = 504
let MTLPixelFormatYCBCR10_420_2P: UInt = 505
let MTLPixelFormatYCBCR10_422_2P: UInt = 506
let MTLPixelFormatYCBCR10_444_2P: UInt = 507
let MTLPixelFormatYCBCR10_420_2P_PACKED: UInt = 508
let MTLPixelFormatYCBCR10_422_2P_PACKED: UInt = 509
let MTLPixelFormatYCBCR10_444_2P_PACKED: UInt = 510

let MTLPixelFormatYCBCR8_420_2P_sRGB: UInt = 520
let MTLPixelFormatYCBCR8_422_1P_sRGB: UInt = 521
let MTLPixelFormatYCBCR8_422_2P_sRGB: UInt = 522
let MTLPixelFormatYCBCR8_444_2P_sRGB: UInt = 523
let MTLPixelFormatYCBCR10_444_1P_sRGB: UInt = 524
let MTLPixelFormatYCBCR10_420_2P_sRGB: UInt = 525
let MTLPixelFormatYCBCR10_422_2P_sRGB: UInt = 526
let MTLPixelFormatYCBCR10_444_2P_sRGB: UInt = 527
let MTLPixelFormatYCBCR10_420_2P_PACKED_sRGB: UInt = 528
let MTLPixelFormatYCBCR10_422_2P_PACKED_sRGB: UInt = 529
let MTLPixelFormatYCBCR10_444_2P_PACKED_sRGB: UInt = 530

let MTLPixelFormatRGB8_420_2P: UInt = 540
let MTLPixelFormatRGB8_422_2P: UInt = 541
let MTLPixelFormatRGB8_444_2P: UInt = 542
let MTLPixelFormatRGB10_420_2P: UInt = 543
let MTLPixelFormatRGB10_422_2P: UInt = 544
let MTLPixelFormatRGB10_444_2P: UInt = 545
let MTLPixelFormatRGB10_420_2P_PACKED: UInt = 546
let MTLPixelFormatRGB10_422_2P_PACKED: UInt = 547
let MTLPixelFormatRGB10_444_2P_PACKED: UInt = 548

let MTLPixelFormatRGB10A8_2P_XR10: UInt = 550
let MTLPixelFormatRGB10A8_2P_XR10_sRGB: UInt = 551
let MTLPixelFormatBGRA10_XR: UInt = 552
let MTLPixelFormatBGRA10_XR_sRGB: UInt = 553
let MTLPixelFormatBGR10_XR: UInt = 554
let MTLPixelFormatBGR10_XR_sRGB: UInt = 555
let MTLPixelFormatRGBA16Float_XR: UInt = 556

let MTLPixelFormatYCBCRA8_444_1P: UInt = 560

let MTLPixelFormatYCBCR12_420_2P: UInt = 570
let MTLPixelFormatYCBCR12_422_2P: UInt = 571
let MTLPixelFormatYCBCR12_444_2P: UInt = 572
let MTLPixelFormatYCBCR12_420_2P_PQ: UInt = 573
let MTLPixelFormatYCBCR12_422_2P_PQ: UInt = 574
let MTLPixelFormatYCBCR12_444_2P_PQ: UInt = 575
let MTLPixelFormatR10Unorm_X6: UInt = 576
let MTLPixelFormatR10Unorm_X6_sRGB: UInt = 577
let MTLPixelFormatRG10Unorm_X12: UInt = 578
let MTLPixelFormatRG10Unorm_X12_sRGB: UInt = 579
let MTLPixelFormatYCBCR12_420_2P_PACKED: UInt = 580
let MTLPixelFormatYCBCR12_422_2P_PACKED: UInt = 581
let MTLPixelFormatYCBCR12_444_2P_PACKED: UInt = 582
let MTLPixelFormatYCBCR12_420_2P_PACKED_PQ: UInt = 583
let MTLPixelFormatYCBCR12_422_2P_PACKED_PQ: UInt = 584
let MTLPixelFormatYCBCR12_444_2P_PACKED_PQ: UInt = 585
let MTLPixelFormatRGB10A2Unorm_sRGB: UInt = 586
let MTLPixelFormatRGB10A2Unorm_PQ: UInt = 587
let MTLPixelFormatR10Unorm_PACKED: UInt = 588
let MTLPixelFormatRG10Unorm_PACKED: UInt = 589
let MTLPixelFormatYCBCR10_444_1P_XR: UInt = 590
let MTLPixelFormatYCBCR10_420_2P_XR: UInt = 591
let MTLPixelFormatYCBCR10_422_2P_XR: UInt = 592
let MTLPixelFormatYCBCR10_444_2P_XR: UInt = 593
let MTLPixelFormatYCBCR10_420_2P_PACKED_XR: UInt = 594
let MTLPixelFormatYCBCR10_422_2P_PACKED_XR: UInt = 595
let MTLPixelFormatYCBCR10_444_2P_PACKED_XR: UInt = 596
let MTLPixelFormatYCBCR12_420_2P_XR: UInt = 597
let MTLPixelFormatYCBCR12_422_2P_XR: UInt = 598
let MTLPixelFormatYCBCR12_444_2P_XR: UInt = 599
let MTLPixelFormatYCBCR12_420_2P_PACKED_XR: UInt = 600
let MTLPixelFormatYCBCR12_422_2P_PACKED_XR: UInt = 601
let MTLPixelFormatYCBCR12_444_2P_PACKED_XR: UInt = 602
let MTLPixelFormatR12Unorm_X4: UInt = 603
let MTLPixelFormatR12Unorm_X4_PQ: UInt = 604
let MTLPixelFormatRG12Unorm_X8: UInt = 605
let MTLPixelFormatR10Unorm_X6_PQ: UInt = 606
//
// end Metal pixel formats
//

// https://github.com/WebKit/WebKit/blob/f86d3400c875519b3f3c368f1ea9a37ed8a1d11b/Source/WebGPU/WebGPU/BindGroup.mm#L43
let kCVPixelFormatType_420YpCbCr10PackedBiPlanarFullRange = 0x70663230 as OSType // pf20
let kCVPixelFormatType_422YpCbCr10PackedBiPlanarFullRange = 0x70663232 as OSType // pf22
let kCVPixelFormatType_444YpCbCr10PackedBiPlanarFullRange = 0x70663434 as OSType // pf44

let kCVPixelFormatType_420YpCbCr10PackedBiPlanarVideoRange = 0x70343230 as OSType // p420
let kCVPixelFormatType_422YpCbCr10PackedBiPlanarVideoRange = 0x70343232 as OSType // p422
let kCVPixelFormatType_444YpCbCr10PackedBiPlanarVideoRange = 0x70343434 as OSType // p444

// Apparently kCVPixelFormatType_Lossless_420YpCbCr8BiPlanarVideoRange is known as kCVPixelFormatType_AGX_420YpCbCr8BiPlanarVideoRange in WebKit.

// Other formats Apple forgot
let kCVPixelFormatType_Lossy_420YpCbCr10PackedBiPlanarFullRange = 0x2D786630 as OSType // -xf0
let kCVPixelFormatType_Lossless_422YpCbCr10PackedBiPlanarFullRange = 0x26786632 as OSType // &xf2
let kCVPixelFormatType_Lossy_422YpCbCr10PackedBiPlanarFullRange = 0x2D786632 as OSType // -xf2
let kCVPixelFormatType_Lossless_420YpCbCr10PackedBiPlanarFullRange_compat = 0x26786630 as OSType // &xf0

struct VideoHandler {
    // Useful for debugging.
    static let coreVideoPixelFormatToStr: [OSType:String] = [
        kCVPixelFormatType_128RGBAFloat: "128RGBAFloat",
        kCVPixelFormatType_14Bayer_BGGR: "BGGR",
        kCVPixelFormatType_14Bayer_GBRG: "GBRG",
        kCVPixelFormatType_14Bayer_GRBG: "GRBG",
        kCVPixelFormatType_14Bayer_RGGB: "RGGB",
        kCVPixelFormatType_16BE555: "16BE555",
        kCVPixelFormatType_16BE565: "16BE565",
        kCVPixelFormatType_16Gray: "16Gray",
        kCVPixelFormatType_16LE5551: "16LE5551",
        kCVPixelFormatType_16LE555: "16LE555",
        kCVPixelFormatType_16LE565: "16LE565",
        kCVPixelFormatType_16VersatileBayer: "16VersatileBayer",
        kCVPixelFormatType_1IndexedGray_WhiteIsZero: "WhiteIsZero",
        kCVPixelFormatType_1Monochrome: "1Monochrome",
        kCVPixelFormatType_24BGR: "24BGR",
        kCVPixelFormatType_24RGB: "24RGB",
        kCVPixelFormatType_2Indexed: "2Indexed",
        kCVPixelFormatType_2IndexedGray_WhiteIsZero: "WhiteIsZero",
        kCVPixelFormatType_30RGB: "30RGB",
        kCVPixelFormatType_30RGBLEPackedWideGamut: "30RGBLEPackedWideGamut",
        kCVPixelFormatType_32ABGR: "32ABGR",
        kCVPixelFormatType_32ARGB: "32ARGB",
        kCVPixelFormatType_32AlphaGray: "32AlphaGray",
        kCVPixelFormatType_32BGRA: "32BGRA",
        kCVPixelFormatType_32RGBA: "32RGBA",
        kCVPixelFormatType_40ARGBLEWideGamut: "40ARGBLEWideGamut",
        kCVPixelFormatType_40ARGBLEWideGamutPremultiplied: "40ARGBLEWideGamutPremultiplied",
        kCVPixelFormatType_420YpCbCr10BiPlanarFullRange: "420YpCbCr10BiPlanarFullRange",
        kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange: "420YpCbCr10BiPlanarVideoRange",
        kCVPixelFormatType_420YpCbCr8BiPlanarFullRange: "420YpCbCr8BiPlanarFullRange",
        kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange: "420YpCbCr8BiPlanarVideoRange",
        kCVPixelFormatType_420YpCbCr8Planar: "420YpCbCr8Planar",
        kCVPixelFormatType_420YpCbCr8PlanarFullRange: "420YpCbCr8PlanarFullRange",
        kCVPixelFormatType_420YpCbCr8VideoRange_8A_TriPlanar: "TriPlanar",
        kCVPixelFormatType_422YpCbCr10: "422YpCbCr10",
        kCVPixelFormatType_422YpCbCr10BiPlanarFullRange: "422YpCbCr10BiPlanarFullRange",
        kCVPixelFormatType_422YpCbCr10BiPlanarVideoRange: "422YpCbCr10BiPlanarVideoRange",
        kCVPixelFormatType_422YpCbCr16: "422YpCbCr16",
        kCVPixelFormatType_422YpCbCr16BiPlanarVideoRange: "422YpCbCr16BiPlanarVideoRange",
        kCVPixelFormatType_422YpCbCr8: "422YpCbCr8",
        kCVPixelFormatType_422YpCbCr8BiPlanarFullRange: "422YpCbCr8BiPlanarFullRange",
        kCVPixelFormatType_422YpCbCr8BiPlanarVideoRange: "422YpCbCr8BiPlanarVideoRange",
        kCVPixelFormatType_422YpCbCr8FullRange: "422YpCbCr8FullRange",
        kCVPixelFormatType_422YpCbCr8_yuvs: "yuvs",
        kCVPixelFormatType_422YpCbCr_4A_8BiPlanar: "8BiPlanar",
        kCVPixelFormatType_4444AYpCbCr16: "4444AYpCbCr16",
        kCVPixelFormatType_4444AYpCbCr8: "4444AYpCbCr8",
        kCVPixelFormatType_4444YpCbCrA8: "4444YpCbCrA8",
        kCVPixelFormatType_4444YpCbCrA8R: "4444YpCbCrA8R",
        kCVPixelFormatType_444YpCbCr10: "444YpCbCr10",
        kCVPixelFormatType_444YpCbCr10BiPlanarFullRange: "444YpCbCr10BiPlanarFullRange",
        kCVPixelFormatType_444YpCbCr10BiPlanarVideoRange: "444YpCbCr10BiPlanarVideoRange",
        kCVPixelFormatType_444YpCbCr16BiPlanarVideoRange: "444YpCbCr16BiPlanarVideoRange",
        kCVPixelFormatType_444YpCbCr16VideoRange_16A_TriPlanar: "TriPlanar",
        kCVPixelFormatType_444YpCbCr8: "444YpCbCr8",
        kCVPixelFormatType_444YpCbCr8BiPlanarFullRange: "444YpCbCr8BiPlanarFullRange",
        kCVPixelFormatType_444YpCbCr8BiPlanarVideoRange: "444YpCbCr8BiPlanarVideoRange",
        kCVPixelFormatType_48RGB: "48RGB",
        kCVPixelFormatType_4Indexed: "4Indexed",
        kCVPixelFormatType_4IndexedGray_WhiteIsZero: "WhiteIsZero",
        kCVPixelFormatType_64ARGB: "64ARGB",
        kCVPixelFormatType_64RGBAHalf: "64RGBAHalf",
        kCVPixelFormatType_64RGBALE: "64RGBALE",
        kCVPixelFormatType_64RGBA_DownscaledProResRAW: "DownscaledProResRAW",
        kCVPixelFormatType_8Indexed: "8Indexed",
        kCVPixelFormatType_8IndexedGray_WhiteIsZero: "WhiteIsZero",
        kCVPixelFormatType_ARGB2101010LEPacked: "ARGB2101010LEPacked",
        kCVPixelFormatType_DepthFloat16: "DepthFloat16",
        kCVPixelFormatType_DepthFloat32: "DepthFloat32",
        kCVPixelFormatType_DisparityFloat16: "DisparityFloat16",
        kCVPixelFormatType_DisparityFloat32: "DisparityFloat32",
        kCVPixelFormatType_Lossless_32BGRA: "32BGRA",
        kCVPixelFormatType_Lossless_420YpCbCr10PackedBiPlanarFullRange_compat: "Lossless_420YpCbCr10PackedBiPlanarFullRange",
        kCVPixelFormatType_Lossless_420YpCbCr10PackedBiPlanarVideoRange: "Lossless_420YpCbCr10PackedBiPlanarVideoRange",
        kCVPixelFormatType_Lossless_420YpCbCr8BiPlanarFullRange: "Lossless_420YpCbCr8BiPlanarFullRange",
        kCVPixelFormatType_Lossless_420YpCbCr8BiPlanarVideoRange: "Lossless_420YpCbCr8BiPlanarVideoRange",
        kCVPixelFormatType_Lossless_422YpCbCr10PackedBiPlanarVideoRange: "Lossless_422YpCbCr10PackedBiPlanarVideoRange",
        kCVPixelFormatType_Lossless_422YpCbCr10PackedBiPlanarFullRange: "Lossless_422YpCbCr10PackedBiPlanarFullRange",
        kCVPixelFormatType_Lossy_32BGRA: "32BGRA",
        kCVPixelFormatType_Lossy_420YpCbCr10PackedBiPlanarFullRange: "Lossy_420YpCbCr10PackedBiPlanarFullRange",
        kCVPixelFormatType_Lossy_420YpCbCr10PackedBiPlanarVideoRange: "Lossy_420YpCbCr10PackedBiPlanarVideoRange",
        kCVPixelFormatType_Lossy_420YpCbCr8BiPlanarFullRange: "Lossy_420YpCbCr8BiPlanarFullRange",
        kCVPixelFormatType_Lossy_420YpCbCr8BiPlanarVideoRange: "Lossy_420YpCbCr8BiPlanarVideoRange",
        kCVPixelFormatType_Lossy_422YpCbCr10PackedBiPlanarFullRange: "Lossy_422YpCbCr10PackedBiPlanarFullRange",
        kCVPixelFormatType_Lossy_422YpCbCr10PackedBiPlanarVideoRange: "Lossy_422YpCbCr10PackedBiPlanarVideoRange",
        kCVPixelFormatType_OneComponent10: "OneComponent10",
        kCVPixelFormatType_OneComponent12: "OneComponent12",
        kCVPixelFormatType_OneComponent16: "OneComponent16",
        kCVPixelFormatType_OneComponent16Half: "OneComponent16Half",
        kCVPixelFormatType_OneComponent32Float: "OneComponent32Float",
        kCVPixelFormatType_OneComponent8: "OneComponent8",
        kCVPixelFormatType_TwoComponent16: "TwoComponent16",
        kCVPixelFormatType_TwoComponent16Half: "TwoComponent16Half",
        kCVPixelFormatType_TwoComponent32Float: "TwoComponent32Float",
        kCVPixelFormatType_TwoComponent8: "TwoComponent8",
        
        kCVPixelFormatType_420YpCbCr10PackedBiPlanarFullRange: "420YpCbCr10PackedBiPlanarFullRange",
        kCVPixelFormatType_422YpCbCr10PackedBiPlanarFullRange: "kCVPixelFormatType_422YpCbCr10PackedBiPlanarFullRange",
        kCVPixelFormatType_444YpCbCr10PackedBiPlanarFullRange: "kCVPixelFormatType_444YpCbCr10PackedBiPlanarFullRange",
        kCVPixelFormatType_420YpCbCr10PackedBiPlanarVideoRange: "kCVPixelFormatType_420YpCbCr10PackedBiPlanarVideoRange",
        kCVPixelFormatType_422YpCbCr10PackedBiPlanarVideoRange: "kCVPixelFormatType_422YpCbCr10PackedBiPlanarVideoRange",
        kCVPixelFormatType_444YpCbCr10PackedBiPlanarVideoRange: "kCVPixelFormatType_444YpCbCr10PackedBiPlanarVideoRange",
        
        // Internal formats?
        0x61766331: "NonDescriptH264",
        0x68766331: "NonDescriptHVC1"
    ]
    
    // Get bits per component for video format
    static func getBpcForVideoFormat(_ videoFormat: CMFormatDescription) -> Int {
        let bpcRaw = videoFormat.extensions["BitsPerComponent" as CFString]
        return (bpcRaw != nil ? bpcRaw as! NSNumber : 8).intValue
    }
    
    // Returns true if video format is full-range
    static func getIsFullRangeForVideoFormat(_ videoFormat: CMFormatDescription) -> Bool {
        let isFullVideoRaw = videoFormat.extensions["FullRangeVideo" as CFString]
        return ((isFullVideoRaw != nil ? isFullVideoRaw as! NSNumber : 0).intValue != 0)
    }
    
    // The Metal texture formats for each of the planes of a given CVPixelFormatType
    static func getTextureTypesForFormat(_ format: OSType) -> [MTLPixelFormat]
    {
        switch(format) {
            // 8-bit biplanar
            case kCVPixelFormatType_Lossy_420YpCbCr8BiPlanarVideoRange,
                 kCVPixelFormatType_Lossless_420YpCbCr8BiPlanarVideoRange,
                 kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                 kCVPixelFormatType_Lossy_420YpCbCr8BiPlanarFullRange,
                 kCVPixelFormatType_Lossless_420YpCbCr8BiPlanarFullRange,
                 kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                 kCVPixelFormatType_422YpCbCr8BiPlanarVideoRange,
                 kCVPixelFormatType_Lossy_420YpCbCr8BiPlanarFullRange,
                 kCVPixelFormatType_Lossless_420YpCbCr8BiPlanarFullRange,
                 kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                 kCVPixelFormatType_444YpCbCr8BiPlanarVideoRange,
                 kCVPixelFormatType_444YpCbCr8BiPlanarFullRange:
                return forceFastSecretTextureFormats ? [MTLPixelFormat.init(rawValue: MTLPixelFormatYCBCR8_420_2P_sRGB)!, MTLPixelFormat.invalid] : [MTLPixelFormat.r8Unorm, MTLPixelFormat.rg8Unorm]

            // 10-bit biplanar
            case kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange,
                 kCVPixelFormatType_420YpCbCr10BiPlanarFullRange,
                 kCVPixelFormatType_422YpCbCr10BiPlanarVideoRange,
                 kCVPixelFormatType_422YpCbCr10BiPlanarFullRange,
                 kCVPixelFormatType_444YpCbCr10BiPlanarVideoRange,
                 kCVPixelFormatType_444YpCbCr10BiPlanarFullRange:
                return forceFastSecretTextureFormats ? [MTLPixelFormat.init(rawValue: MTLPixelFormatYCBCR10_420_2P_sRGB)!, MTLPixelFormat.invalid] : [MTLPixelFormat.r16Unorm, MTLPixelFormat.rg16Unorm]

            //
            // If it's good enough for WebKit, it's good enough for me.
            // https://github.com/WebKit/WebKit/blob/f86d3400c875519b3f3c368f1ea9a37ed8a1d11b/Source/WebGPU/WebGPU/MetalSPI.h#L30
            // https://github.com/WebKit/WebKit/blob/f86d3400c875519b3f3c368f1ea9a37ed8a1d11b/Source/WebGPU/WebGPU/BindGroup.mm#L43
            // https://github.com/WebKit/WebKit/blob/ef1916c078676dca792cef30502a765d398dcc18/Source/WebGPU/WebGPU/BindGroup.mm#L416
            //
            // 10-bit packed biplanar 4:2:0
            case kCVPixelFormatType_Lossy_420YpCbCr10PackedBiPlanarVideoRange,
                 kCVPixelFormatType_Lossless_420YpCbCr10PackedBiPlanarVideoRange,
                 kCVPixelFormatType_Lossy_420YpCbCr10PackedBiPlanarFullRange,
                 kCVPixelFormatType_Lossless_420YpCbCr10PackedBiPlanarFullRange_compat,
                 kCVPixelFormatType_420YpCbCr10PackedBiPlanarFullRange,
                 kCVPixelFormatType_420YpCbCr10PackedBiPlanarVideoRange:
                return [MTLPixelFormat.init(rawValue: MTLPixelFormatYCBCR10_420_2P_PACKED_sRGB)!, MTLPixelFormat.invalid] // MTLPixelFormatYCBCR10_420_2P_PACKED
            
            // 10-bit packed biplanar 4:2:2
            case kCVPixelFormatType_Lossy_422YpCbCr10PackedBiPlanarVideoRange,
                 kCVPixelFormatType_Lossless_422YpCbCr10PackedBiPlanarVideoRange,
                 kCVPixelFormatType_Lossy_422YpCbCr10PackedBiPlanarFullRange,
                 kCVPixelFormatType_Lossless_422YpCbCr10PackedBiPlanarFullRange,
                 kCVPixelFormatType_422YpCbCr10PackedBiPlanarFullRange,
                 kCVPixelFormatType_422YpCbCr10PackedBiPlanarVideoRange:
                return [MTLPixelFormat.init(rawValue: MTLPixelFormatYCBCR10_422_2P_PACKED_sRGB)!, MTLPixelFormat.invalid] // MTLPixelFormatYCBCR10_422_2P_PACKED
            
            // 10-bit packed biplanar 4:4:4
            case kCVPixelFormatType_444YpCbCr10PackedBiPlanarFullRange,
                 kCVPixelFormatType_444YpCbCr10PackedBiPlanarVideoRange:
                return [MTLPixelFormat.init(rawValue: MTLPixelFormatYCBCR10_444_2P_PACKED_sRGB)!, MTLPixelFormat.invalid] // MTLPixelFormatYCBCR10_444_2P_PACKED

            // Guess 8-bit biplanar otherwise
            default:
                let formatStr = coreVideoPixelFormatToStr[format, default: "unknown"]
                print("Warning: Pixel format \(formatStr) (\(format)) is not currently accounted for! Returning 8-bit vals")
                return [MTLPixelFormat.r8Unorm, MTLPixelFormat.rg8Unorm]
        }
    }
    
    static func isFormatSecret(_ format: OSType) -> Bool
    {
        switch(format) {
            // Packed formats, requires secret MTLTexture pixel formats
            case kCVPixelFormatType_Lossy_420YpCbCr10PackedBiPlanarVideoRange,
                 kCVPixelFormatType_Lossless_420YpCbCr10PackedBiPlanarVideoRange,
                 kCVPixelFormatType_Lossy_420YpCbCr10PackedBiPlanarFullRange,
                 kCVPixelFormatType_Lossless_420YpCbCr10PackedBiPlanarFullRange_compat,
                 kCVPixelFormatType_Lossy_422YpCbCr10PackedBiPlanarVideoRange,
                 kCVPixelFormatType_Lossless_422YpCbCr10PackedBiPlanarVideoRange,
                 kCVPixelFormatType_Lossy_422YpCbCr10PackedBiPlanarFullRange,
                 kCVPixelFormatType_Lossless_422YpCbCr10PackedBiPlanarFullRange,
                 kCVPixelFormatType_420YpCbCr10PackedBiPlanarFullRange,
                 kCVPixelFormatType_422YpCbCr10PackedBiPlanarFullRange,
                 kCVPixelFormatType_444YpCbCr10PackedBiPlanarFullRange,
                 kCVPixelFormatType_420YpCbCr10PackedBiPlanarVideoRange,
                 kCVPixelFormatType_422YpCbCr10PackedBiPlanarVideoRange,
                 kCVPixelFormatType_444YpCbCr10PackedBiPlanarVideoRange:
            return true;
            
            // Not packed, but there's still a nice pixel format for them that's a
            // few hundred microseconds faster.
            case kCVPixelFormatType_Lossy_420YpCbCr8BiPlanarVideoRange, // 8-bit
                 kCVPixelFormatType_Lossless_420YpCbCr8BiPlanarVideoRange,
                 kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                 kCVPixelFormatType_Lossy_420YpCbCr8BiPlanarFullRange,
                 kCVPixelFormatType_Lossless_420YpCbCr8BiPlanarFullRange,
                 kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                 kCVPixelFormatType_422YpCbCr8BiPlanarVideoRange,
                 kCVPixelFormatType_Lossy_420YpCbCr8BiPlanarFullRange,
                 kCVPixelFormatType_Lossless_420YpCbCr8BiPlanarFullRange,
                 kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                 kCVPixelFormatType_444YpCbCr8BiPlanarVideoRange,
                 kCVPixelFormatType_444YpCbCr8BiPlanarFullRange,
                 
                 // 10-bit
                 kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange,
                 kCVPixelFormatType_420YpCbCr10BiPlanarFullRange,
                 kCVPixelFormatType_422YpCbCr10BiPlanarVideoRange,
                 kCVPixelFormatType_422YpCbCr10BiPlanarFullRange,
                 kCVPixelFormatType_444YpCbCr10BiPlanarVideoRange,
                 kCVPixelFormatType_444YpCbCr10BiPlanarFullRange:
                return forceFastSecretTextureFormats
            default:
                return false
        }
    }
    
    static func getYUVTransformForVideoFormat(_ videoFormat: CMFormatDescription) -> simd_float4x4 {
        let fmtYCbCrMatrixRaw = videoFormat.extensions["CVImageBufferYCbCrMatrix" as CFString]
        let fmtYCbCrMatrix = (fmtYCbCrMatrixRaw != nil ? fmtYCbCrMatrixRaw as! CFString : "unknown" as CFString)

        // Bless this page for ending my stint of plugging in random values
        // from other projects:
        // https://kdashg.github.io/misc/colors/from-coeffs.html
        let ycbcrJPEGToRGB = simd_float4x4([
            simd_float4(+1.0000, +1.0000, +1.0000, +0.0000), // Y
            simd_float4(+0.0000, -0.3441, +1.7720, +0.0000), // Cb
            simd_float4(+1.4020, -0.7141, +0.0000, +0.0000), // Cr
            simd_float4(-0.7010, +0.5291, -0.8860, +1.0000)]  // offsets
        );

        // BT.601 Full range (8-bit)
        let bt601ToRGBFull8bit = simd_float4x4([
            simd_float4(+1.0000000, +1.0000000, +1.0000000, +0.0000), // Y
            simd_float4(+0.0000000, -0.3454912, +1.7789764, +0.0000), // Cb
            simd_float4(+1.4075197, -0.7169478, -0.0000000, +0.0000), // Cr
            simd_float4(-0.7065197, +0.5333027, -0.8929764, +1.0000)]
        );

        // BT.2020 Full range (8-bit)
        let bt2020ToRGBFull8bit = simd_float4x4([
            simd_float4(+1.0000000, +1.0000000, +1.0000000, +0.0000), // Y
            simd_float4(-0.0000000, -0.1652010, +1.8888071, +0.0000), // Cb
            simd_float4(+1.4804055, -0.5736025, +0.0000000, +0.0000), // Cr
            simd_float4(-0.7431055, +0.3708504, -0.9481071, +1.0000)]
        );
 
        // BT.709 Full range (8-bit)
        let bt709ToRGBFull8bit = simd_float4x4([
            simd_float4(+1.0000000, +1.0000000, +1.0000000, +0.0000), // Y
            simd_float4(+0.0000000, -0.1880618, +1.8629055, +0.0000), // Cb
            simd_float4(+1.5810000, -0.4699673, +0.0000000, +0.0000), // Cr
            simd_float4(-0.7936000, +0.3303048, -0.9351055, +1.0000)]
        );

        // BT.601 Full range (10-bit)
        let bt601ToRGBFull10bit = simd_float4x4([
            simd_float4(+1.0000000, +1.0000000, +1.0000000, +0.0000), // Y
            simd_float4(+0.0000000, -0.3444730, +1.7737339, +0.0000), // Cb
            simd_float4(+1.4033718, -0.7148350, +0.0000000, +0.0000), // Cr
            simd_float4(-0.7023718, +0.5301718, -0.8877339, +1.0000)]
        );

        // BT.2020 Full range (10-bit)
        let bt2020ToRGBFull10bit = simd_float4x4([
            simd_float4(+1.0000000, +1.0000000, +1.0000000, +0.0000), // Y
            simd_float4(-0.0000000, -0.1647141, +1.8832409, +0.0000), // Cb
            simd_float4(+1.4760429, -0.5719122, +0.0000000, +0.0000), // Cr
            simd_float4(-0.7387429, +0.3686732, -0.9425409, +1.0000)]
        );

        // BT.709 Full range (10-bit)
        let bt709ToRGBFull10bit = simd_float4x4([
            simd_float4(+1.0000000, +1.0000000, +1.0000000, +0.0000), // Y
            simd_float4(+0.0000000, -0.1875076, +1.8574157, +0.0000), // Cb
            simd_float4(+1.5763409, -0.4685823, +0.0000000, +0.0000), // Cr
            simd_float4(-0.7889409, +0.3283656, -0.9296157, +1.0000)]
        );

        // BT.2020 Limited range
        /*let bt2020ToRGBLimited = simd_float4x4([
            simd_float4(+1.1632, +1.1632, +1.1632, +0.0000), // Y
            simd_float4(+0.0002, -0.1870, +2.1421, +0.0000), // Cb
            simd_float4(+1.6794, -0.6497, +0.0008, +0.0000), // Cr
            simd_float4(-0.91607960784, +0.34703254902, -1.14866392157, +1.0000)]  // offsets
        );*/

        // BT.709 Limited range
        /*let bt709ToRGBLimited = simd_float4x4([
            simd_float4(+1.1644, +1.1644, +1.1644, +0.0000), // Y
            simd_float4(+0.0001, -0.2133, +2.1125, +0.0000), // Cb
            simd_float4(+1.7969, -0.5342, -0.0002, +0.0000), // Cr
            simd_float4(-0.97506392156, 0.30212823529, -1.1333145098, +1.0000)]  // offsets
        );*/

        let bpc = getBpcForVideoFormat(videoFormat)
        if bpc == 10 {
            switch(fmtYCbCrMatrix) {
                case kCVImageBufferYCbCrMatrix_ITU_R_601_4:
                    return bt601ToRGBFull10bit;
                case kCVImageBufferYCbCrMatrix_ITU_R_709_2:
                    return bt709ToRGBFull10bit;
                case kCVImageBufferYCbCrMatrix_ITU_R_2020:
                    return bt2020ToRGBFull10bit;
                default:
                    return ycbcrJPEGToRGB;
            }
        }
        else {
            switch(fmtYCbCrMatrix) {
                case kCVImageBufferYCbCrMatrix_ITU_R_601_4:
                    return bt601ToRGBFull8bit;
                case kCVImageBufferYCbCrMatrix_ITU_R_709_2:
                    return bt709ToRGBFull8bit;
                case kCVImageBufferYCbCrMatrix_ITU_R_2020:
                    return bt2020ToRGBFull8bit;
                default:
                    return ycbcrJPEGToRGB;
            }
        }
    }
    
    static var testCalled = false
    static var metalTextureCache: CVMetalTextureCache? = nil
    static var device: MTLDevice? = nil
    
    // FEEDBACK: LOOK HERE
    // The metal texture conversion and compression checks
    static func testCallback(pixelBuffer: CVImageBuffer?, prefix: String) {
        guard let pixelBuffer = pixelBuffer else {
            print("no buffer, please wait...")
            return
        }
        let textureTypes = VideoHandler.getTextureTypesForFormat(CVPixelBufferGetPixelFormatType(pixelBuffer))
        
        for i in 0...1 {
            var textureOut:CVMetalTexture! = nil
            var err:OSStatus = 0
            let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, i)
            let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, i)
            
            if textureTypes[i] == MTLPixelFormat.invalid {
                break
            }
            
            err = CVMetalTextureCacheCreateTextureFromImage(
                    nil, metalTextureCache!, pixelBuffer, nil, textureTypes[i],
                    width, height, i, &textureOut);
            
            if err != 0 {
                fatalError("\(prefix) CVMetalTextureCacheCreateTextureFromImage \(err)")
            }
            guard let metalTexture = CVMetalTextureGetTexture(textureOut) else {
                fatalError("\(prefix) CVMetalTextureCacheCreateTextureFromImage")
            }
            if !((metalTexture.debugDescription?.contains("decompressedPixelFormat") ?? true) || (metalTexture.debugDescription?.contains("isCompressed = 1") ?? true)) {
                print("\(prefix) result: NO COMPRESSION ON VT FRAME!!!! AAAAAAAAA")
                print("Texture format printout:")
                print(metalTexture)
                print("-------")
                print("")
                print("")
                return
            }
        }
        
        print("\(prefix) result: Yay! Compression!")
        return
    }
    
    static func testCallbackA(pixelBuffer: CVImageBuffer?) {
        testCallback(pixelBuffer: pixelBuffer, prefix: "Bug Variant A")
    }
    
    static func testCallbackB(pixelBuffer: CVImageBuffer?) {
        testCallback(pixelBuffer: pixelBuffer, prefix: "Bug Variant B")
    }
    
    static func testCallbackC(pixelBuffer: CVImageBuffer?) {
        testCallback(pixelBuffer: pixelBuffer, prefix: "No Format Conversion")
    }
    
    // FEEDBACK: LOOK HERE
    // The main test loop
    static func runTest() {
        if testCalled {
            return
        }
        testCalled = true
        
        VideoHandler.device = MTLCreateSystemDefaultDevice()
        if CVMetalTextureCacheCreate(nil, nil, VideoHandler.device!, nil, &VideoHandler.metalTextureCache) != 0 {
            fatalError("CVMetalTextureCacheCreate")
        }

        var vtDecompressionSessionA: VTDecompressionSession? = nil
        var videoFormatA: CMFormatDescription? = nil
        var vtDecompressionSessionB: VTDecompressionSession? = nil
        var videoFormatB: CMFormatDescription? = nil
        var vtDecompressionSessionC: VTDecompressionSession? = nil
        var videoFormatC: CMFormatDescription? = nil

        guard let (_, nal) = VideoHandler.pollNalA() else {
           print("create decoder: failed to poll nal?!")
           return
        }
        if (nal[3] == 0x01 && nal[4] & 0x1f == H264_NAL_TYPE_SPS) || (nal[2] == 0x01 && nal[3] & 0x1f == H264_NAL_TYPE_SPS) {
            // here we go!
            if triggerDecompressedBugTypeA {
                (vtDecompressionSessionA, videoFormatA) = VideoHandler.createVideoDecoder(initialNals: nal, codec: H264_NAL_TYPE_SPS, whichBug: 0)
            }
            if triggerDecompressedBugTypeB {
                (vtDecompressionSessionB, videoFormatB) = VideoHandler.createVideoDecoder(initialNals: nal, codec: H264_NAL_TYPE_SPS, whichBug: 1)
            }
            (vtDecompressionSessionC, videoFormatC) = VideoHandler.createVideoDecoder(initialNals: nal, codec: H264_NAL_TYPE_SPS, whichBug: 2)
        } else if (nal[3] == 0x01 && (nal[4] & 0x7E) >> 1 == HEVC_NAL_TYPE_VPS) || (nal[2] == 0x01 && (nal[3] & 0x7E) >> 1 == HEVC_NAL_TYPE_VPS) {
            // The NAL unit type is 32 (VPS)
            if triggerDecompressedBugTypeA {
                (vtDecompressionSessionA, videoFormatA) = VideoHandler.createVideoDecoder(initialNals: nal, codec: HEVC_NAL_TYPE_VPS, whichBug: 0)
            }
            if triggerDecompressedBugTypeB {
                (vtDecompressionSessionB, videoFormatB) = VideoHandler.createVideoDecoder(initialNals: nal, codec: HEVC_NAL_TYPE_VPS, whichBug: 1)
            }
            (vtDecompressionSessionC, videoFormatC) = VideoHandler.createVideoDecoder(initialNals: nal, codec: HEVC_NAL_TYPE_VPS, whichBug: 2)
        }
        
        if (vtDecompressionSessionA == nil || videoFormatA == nil) && triggerDecompressedBugTypeA {
            print("Failed to create decoder A")
        }
        if (vtDecompressionSessionB == nil || videoFormatB == nil) && triggerDecompressedBugTypeB {
            print("Failed to create decoder B")
        }
        if vtDecompressionSessionC == nil || videoFormatC == nil {
            print("Failed to create decoder C")
        }
        
        //VideoHandler.feedVideoIntoDecoder(decompressionSession: vtDecompressionSession!, nals: nal, timestamp: 0, videoFormat: videoFormat!, callback: VideoHandler.testCallback)
        
        guard let (_, nalData) = VideoHandler.pollNalB() else {
           print("create decoder: failed to poll nal?!")
           return
        }
        var index = 0
        var skipVps = 1
        var skipSps = 1
        var skipPps = 1
        var skipNormal = 0
        var chunk = Data()
        while index < nalData.count - 4 {
            // Find the start code (0x00000001 or 0x000001)
            if nalData[index] == 0 && nalData[index + 1] == 0 && nalData[index + 2] == 0 && nalData[index + 3] == 1 {
                // NAL unit starts after the start code
                let nalUnitStartIndex = index + 4
                var nalUnitEndIndex = index + 4
                
                if nalUnitStartIndex > nalData.count - 4 {
                    break
                }
                
                // Find the next start code to determine the end of this NAL unit
                for nextIndex in nalUnitStartIndex..<nalData.count - 4 {
                    if nalData[nextIndex] == 0 && nalData[nextIndex + 1] == 0 && nalData[nextIndex + 2] == 0 && nalData[nextIndex + 3] == 1 {
                        nalUnitEndIndex = nextIndex
                        break
                    }
                    nalUnitEndIndex = nalData.count // If no more start codes, this NAL unit goes to the end of the data
                }
                
                let nalUnitType = (nalData[nalUnitStartIndex] & 0x7E) >> 1 // Get NAL unit type (HEVC)
                let nalUnitData = nalData.subdata(in: nalUnitStartIndex-4..<nalUnitEndIndex)
                
                //print("Decode nalUnitType of: \(nalUnitType)")
                //print(nalUnitData[0], nalUnitData[1], nalUnitData[2], nalUnitData[3])
                
                chunk.append(nalUnitData)
                
                switch nalUnitType {
                case 32: // VPS
                    skipVps += 1
                    break
                case 33: // SPS
                    skipSps += 1
                    break
                case 34: // PPS
                    skipPps += 1
                    break
                case 19:
                    skipNormal += 1
                    break
                
                // HACK: mark the packet boundariesin the file with 0-type NALs and submit when we see them
                case 0:
                    //print("feed")
                    if vtDecompressionSessionA != nil && videoFormatA != nil {
                        VideoHandler.feedVideoIntoDecoder(decompressionSession: vtDecompressionSessionA!, nals: chunk, timestamp: 0, videoFormat: videoFormatA!, callback: VideoHandler.testCallbackA)
                    }
                    if vtDecompressionSessionB != nil && videoFormatB != nil {
                        VideoHandler.feedVideoIntoDecoder(decompressionSession: vtDecompressionSessionB!, nals: chunk, timestamp: 0, videoFormat: videoFormatB!, callback: VideoHandler.testCallbackB)
                    }
                    if vtDecompressionSessionC != nil && videoFormatC != nil {
                        VideoHandler.feedVideoIntoDecoder(decompressionSession: vtDecompressionSessionC!, nals: chunk, timestamp: 0, videoFormat: videoFormatC!, callback: VideoHandler.testCallbackC)
                    }
                    chunk = Data()
                    break
                default:
                    break
                }
                
                
                
                
                index = nalUnitEndIndex
            } else {
                index += 1 // Move to the next byte if start code not found
            }
        }
        //VideoHandler.feedVideoIntoDecoder(decompressionSession: vtDecompressionSession!, nals: nalData, timestamp: 0, videoFormat: videoFormat!, callback: VideoHandler.testCallback)
    }

    static func pollNalA() -> (UInt64, Data)? {
        guard
            let url = Bundle.main.url(forResource: "stream_start", withExtension: "h265")
        else {
            print("Failed to open NAL file")
            return nil
        }
        
        do {
            let nalTimestamp: UInt64 = 0
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let ret = (nalTimestamp, data)

            return ret
        }
        catch {
            print("Failed to read NALs")
            print(error)
        }
        return nil
    }
    
    static func pollNalB() -> (UInt64, Data)? {
        guard
            let url = Bundle.main.url(forResource: "stream", withExtension: "h265")
        else {
            print("Failed to open NAL file")
            return nil
        }
        
        do {
            let nalTimestamp: UInt64 = 0
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let ret = (nalTimestamp, data)

            return ret
        }
        catch {
            print("Failed to read NALs")
            print(error)
        }
        return nil
    }
    
    static func createVideoDecoder(initialNals: Data, codec: Int, whichBug: Int) -> (VTDecompressionSession?, CMFormatDescription?) {
        let nalHeader:[UInt8] = [0x00, 0x00, 0x00, 0x01]
        var videoFormat:CMFormatDescription? = nil
        var err:OSStatus = 0
        
        // First two are the SPS and PPS
        // https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/sdk/objc/components/video_codec/nalu_rewriter.cc;l=228;drc=6f86f6af008176e631140e6a80e0a0bca9550143
        
        if (codec == H264_NAL_TYPE_SPS) {
            err = initialNals.withUnsafeBytes { (b:UnsafeRawBufferPointer) in
                let nalOffset0 = b.baseAddress!
                let nalOffset1 = memmem(nalOffset0 + 4, b.count - 4, nalHeader, nalHeader.count)!
                let nalLength0 = UnsafeRawPointer(nalOffset1) - nalOffset0 - 4
                let nalLength1 = b.baseAddress! + b.count - UnsafeRawPointer(nalOffset1) - 4

                let parameterSetPointers = [(nalOffset0 + 4).assumingMemoryBound(to: UInt8.self), UnsafeRawPointer(nalOffset1 + 4).assumingMemoryBound(to: UInt8.self)]
                let parameterSetSizes = [nalLength0, nalLength1]
                return CMVideoFormatDescriptionCreateFromH264ParameterSets(allocator: nil, parameterSetCount: 2, parameterSetPointers: parameterSetPointers, parameterSetSizes: parameterSetSizes, nalUnitHeaderLength: 4, formatDescriptionOut: &videoFormat)
            }
        } else if (codec == HEVC_NAL_TYPE_VPS) {
            let (vps, sps, pps) = extractParameterSets(from: initialNals)
            
            // Ensure parameterSetPointers is an array of non-optional UnsafePointer<UInt8>
            var parameterSetPointers: [UnsafePointer<UInt8>?] = []
            var parameterSetSizes: [Int] = []
            
            if let vps = vps {
                vps.withUnsafeBytes { rawBufferPointer in
                    if let baseAddress = rawBufferPointer.baseAddress {
                        let typedPointer = baseAddress.assumingMemoryBound(to: UInt8.self)
                        parameterSetPointers.append(typedPointer)
                        parameterSetSizes.append(vps.count)
                    }
                }
            }
            
            if let sps = sps {
                sps.withUnsafeBytes { rawBufferPointer in
                    if let baseAddress = rawBufferPointer.baseAddress {
                        let typedPointer = baseAddress.assumingMemoryBound(to: UInt8.self)
                        parameterSetPointers.append(typedPointer)
                        parameterSetSizes.append(sps.count)
                    }
                }
            }
            
            if let pps = pps {
                pps.withUnsafeBytes { rawBufferPointer in
                    if let baseAddress = rawBufferPointer.baseAddress {
                        let typedPointer = baseAddress.assumingMemoryBound(to: UInt8.self)
                        parameterSetPointers.append(typedPointer)
                        parameterSetSizes.append(pps.count)
                    }
                }
            }
            
            // Flatten parameterSetPointers to non-optional before passing to the function
            let nonOptionalParameterSetPointers = parameterSetPointers.compactMap { $0 }
            
            
            // nonOptionalParameterSetPointers is an array of UnsafePointer<UInt8>
            nonOptionalParameterSetPointers.withUnsafeBufferPointer { bufferPointer in
                guard let baseAddress = bufferPointer.baseAddress else { return }
                
                parameterSetSizes.withUnsafeBufferPointer { sizesBufferPointer in
                guard let sizesBaseAddress = sizesBufferPointer.baseAddress else { return }
                   
                    let parameterSetCount = [vps, sps, pps].compactMap { $0 }.count // Only count non-nil parameter sets
                    print("Parameter set count: \(parameterSetCount)")

                    let nalUnitHeaderLength: Int32 = 4 // Typically 4 for HEVC

                    parameterSetSizes.enumerated().forEach { index, size in
                        print("Parameter set \(index) size: \(size)")
                    }
                
                    let status = CMVideoFormatDescriptionCreateFromHEVCParameterSets(
                        allocator: nil,
                        parameterSetCount: parameterSetPointers.count,
                        parameterSetPointers: baseAddress,
                        parameterSetSizes: sizesBaseAddress,
                        nalUnitHeaderLength: nalUnitHeaderLength,
                        extensions: nil,
                        formatDescriptionOut: &videoFormat
                    )
                    
                    // Check if the format description was successfully created
                    if status == noErr, let _ = videoFormat {
                        // Use the format description
                        print("Successfully created CMVideoFormatDescription.")
                    } else {
                        print("Failed to create CMVideoFormatDescription.")
                    }
                }
                
            }
        }

        if err != 0 {
            print("format?!")
            return (nil, nil)
        }

        if videoFormat == nil {
            return (nil, nil)
        }

        print(videoFormat!)
        
        // We need our pixels unpacked for 10-bit so that the Metal textures actually work
        var pixelFormat:OSType? = nil
        let bpc = getBpcForVideoFormat(videoFormat!)
        let isFullRange = getIsFullRangeForVideoFormat(videoFormat!)
        
        // TODO: figure out how to check for 422/444, CVImageBufferChromaLocationBottomField?
        
        // FEEDBACK: LOOK HERE
        // On visionOS 2, setting pixelFormat *at all* causes a copy to an uncompressed MTLTexture buffer
        if bpc == 10 {
            // No 10-bit packing on the output buffer, has an implicit conversion cost (and the textures are decompressed, which is a bug)
            if whichBug == 0 {
                pixelFormat = isFullRange ? kCVPixelFormatType_420YpCbCr10BiPlanarFullRange : kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange
            }
            
            if whichBug == 1 {
                pixelFormat = isFullRange ? kCVPixelFormatType_420YpCbCr10PackedBiPlanarFullRange : kCVPixelFormatType_420YpCbCr10PackedBiPlanarVideoRange // default
            }
        }
        
        let iosurfaceAttributes:[NSString: AnyObject] = [:]
        let videoDecoderSpecification:[NSString: AnyObject] = [kVTVideoDecoderSpecification_EnableHardwareAcceleratedVideoDecoder:kCFBooleanTrue]
        var destinationImageBufferAttributes:[NSString: AnyObject] = [kCVPixelBufferMetalCompatibilityKey: true as NSNumber, kCVPixelBufferPoolMinimumBufferCountKey: 3 as NSNumber, kCVPixelBufferIOSurfacePropertiesKey: iosurfaceAttributes as AnyObject]
        // TODO come back to this maybe idk
        if pixelFormat != nil {
            destinationImageBufferAttributes[kCVPixelBufferPixelFormatTypeKey] = pixelFormat! as NSNumber
        }

        var decompressionSession:VTDecompressionSession? = nil
        err = VTDecompressionSessionCreate(allocator: nil, formatDescription: videoFormat!, decoderSpecification: videoDecoderSpecification as CFDictionary, imageBufferAttributes: destinationImageBufferAttributes as CFDictionary, outputCallback: nil, decompressionSessionOut: &decompressionSession)
        if err != 0 {
            print("format?!")
            return (nil, nil)
        }
        
        if decompressionSession == nil {
            print("no session??")
            return (nil, nil)
        }
        
        return (decompressionSession!, videoFormat!)
    }

    // Function to parse NAL units and extract VPS, SPS, and PPS data
    static func extractParameterSets(from nalData: Data) -> (vps: [UInt8]?, sps: [UInt8]?, pps: [UInt8]?) {
        var vps: [UInt8]?
        var sps: [UInt8]?
        var pps: [UInt8]?
        
        var index = 0
        while index < nalData.count - 4 {
            if vps != nil && sps != nil && pps != nil {
                break
            }
            // Find the start code (0x00000001 or 0x000001)
            if nalData[index] == 0 && nalData[index + 1] == 0 && nalData[index + 2] == 0 && nalData[index + 3] == 1 {
                // NAL unit starts after the start code
                let nalUnitStartIndex = index + 4
                var nalUnitEndIndex = index + 4
                
                // Find the next start code to determine the end of this NAL unit
                for nextIndex in nalUnitStartIndex..<nalData.count - 4 {
                    if nalData[nextIndex] == 0 && nalData[nextIndex + 1] == 0 && nalData[nextIndex + 2] == 0 && nalData[nextIndex + 3] == 1 {
                        nalUnitEndIndex = nextIndex
                        break
                    }
                    nalUnitEndIndex = nalData.count // If no more start codes, this NAL unit goes to the end of the data
                }
                
                let nalUnitType = (nalData[nalUnitStartIndex] & 0x7E) >> 1 // Get NAL unit type (HEVC)
                let nalUnitData = nalData.subdata(in: nalUnitStartIndex..<nalUnitEndIndex)
                
                print("Switch nalUnitType of: \(nalUnitType)")
                switch nalUnitType {
                case 32: // VPS
                    vps = [UInt8](nalUnitData)
                case 33: // SPS
                    sps = [UInt8](nalUnitData)
                case 34: // PPS
                    pps = [UInt8](nalUnitData)
                default:
                    break
                }
                
                index = nalUnitEndIndex
            } else {
                index += 1 // Move to the next byte if start code not found
            }
        }
        
        return (vps, sps, pps)
    }



    // Based on https://webrtc.googlesource.com/src/+/refs/heads/main/common_video/h264/h264_common.cc
    private static func findNaluIndices(buffer: Data) -> [NaluIndex] {
        guard buffer.count >= /* kNaluShortStartSequenceSize */ 3 else {
            return []
        }
        
        var sequences = [NaluIndex]()
        
        let end = buffer.count - /* kNaluShortStartSequenceSize */ 3
        var i = 0
        while i < end {
            if buffer[i + 2] > 1 {
                i += 3
            } else if buffer[i + 2] == 1 {
                if buffer[i + 1] == 0 && buffer[i] == 0 {
                    var index = NaluIndex(startOffset: i, payloadStartOffset: i + 3, payloadSize: 0, threeByteHeader: true)
                    if index.startOffset > 0 && buffer[index.startOffset - 1] == 0 {
                        index.startOffset -= 1
                        index.threeByteHeader = false
                    }
                    
                    if !sequences.isEmpty {
                        sequences[sequences.count - 1].payloadSize = index.startOffset - sequences.last!.payloadStartOffset
                    }
                    
                    sequences.append(index)
                }
                
                i += 3
            } else {
                i += 1
            }
        }
        
        if !sequences.isEmpty {
            sequences[sequences.count - 1].payloadSize = buffer.count - sequences.last!.payloadStartOffset
        }
        
        return sequences
    }
    
    private struct NaluIndex {
        var startOffset: Int
        var payloadStartOffset: Int
        var payloadSize: Int
        var threeByteHeader: Bool
    }
    
    // Based on https://webrtc.googlesource.com/src/+/refs/heads/main/sdk/objc/components/video_codec/nalu_rewriter.cc
    private static func annexBBufferToCMSampleBuffer(buffer: Data, videoFormat: CMFormatDescription) -> CMSampleBuffer? {
        // no SPS/PPS, handled with the initial nals
        
        var err: OSStatus = 0
        
        let naluIndices = findNaluIndices(buffer: buffer)

        // we're replacing the 3/4 nalu headers with a 4 byte length, so add an extra byte on top of the original length for each 3-byte nalu header
        let blockBufferLength = buffer.count + naluIndices.filter(\.threeByteHeader).count
        let blockBuffer = try! CMBlockBuffer(length: blockBufferLength, flags: .assureMemoryNow)
        
        var contiguousBuffer: CMBlockBuffer!
        if !CMBlockBufferIsRangeContiguous(blockBuffer, atOffset: 0, length: 0) {
            err = CMBlockBufferCreateContiguous(allocator: nil, sourceBuffer: blockBuffer, blockAllocator: nil, customBlockSource: nil, offsetToData: 0, dataLength: 0, flags: 0, blockBufferOut: &contiguousBuffer)
            if err != 0 {
                print("CMBlockBufferCreateContiguous error")
                return nil
            }
        } else {
            contiguousBuffer = blockBuffer
        }
        
        var blockBufferSize = 0
        var dataPtr: UnsafeMutablePointer<Int8>!
        err = CMBlockBufferGetDataPointer(contiguousBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &blockBufferSize, dataPointerOut: &dataPtr)
        if err != 0 {
            print("CMBlockBufferGetDataPointer error")
            return nil
        }
        
        //dataPtr.withMemoryRebound(to: UInt8.self, capacity: blockBufferSize) { pointer in
        let pointer = UnsafeMutablePointer<UInt8>(OpaquePointer(dataPtr))!
        var offset = 0
        
        buffer.withUnsafeBytes { (unsafeBytes) in
            let bytes = unsafeBytes.bindMemory(to: UInt8.self).baseAddress!

            for index in naluIndices {
                pointer.advanced(by: offset    ).pointee = UInt8((index.payloadSize >> 24) & 0xFF)
                pointer.advanced(by: offset + 1).pointee = UInt8((index.payloadSize >> 16) & 0xFF)
                pointer.advanced(by: offset + 2).pointee = UInt8((index.payloadSize >>  8) & 0xFF)
                pointer.advanced(by: offset + 3).pointee = UInt8((index.payloadSize      ) & 0xFF)
                offset += 4
                
                pointer.advanced(by: offset).update(from: bytes.advanced(by: index.payloadStartOffset), count: blockBufferSize - offset)
                offset += index.payloadSize
            }
        }
        
        var sampleBuffer: CMSampleBuffer!
        err = CMSampleBufferCreate(allocator: nil, dataBuffer: contiguousBuffer, dataReady: true, makeDataReadyCallback: nil, refcon: nil, formatDescription: videoFormat, sampleCount: 1, sampleTimingEntryCount: 0, sampleTimingArray: nil, sampleSizeEntryCount: 0, sampleSizeArray: nil, sampleBufferOut: &sampleBuffer)
        if err != 0 {
            print("CMSampleBufferCreate error")
            return nil
        }
        
        return sampleBuffer
    }
    
    static func feedVideoIntoDecoder(decompressionSession: VTDecompressionSession, nals: Data, timestamp: UInt64, videoFormat: CMFormatDescription, callback: @escaping (_ imageBuffer: CVImageBuffer?) -> Void) {
        var err:OSStatus = 0
        guard let sampleBuffer = annexBBufferToCMSampleBuffer(buffer: nals, videoFormat: videoFormat) else {
            print("Failed in annexBBufferToCMSampleBuffer")
            return
        }
        err = VTDecompressionSessionDecodeFrame(decompressionSession, sampleBuffer: sampleBuffer, flags: ._EnableAsynchronousDecompression, infoFlagsOut: nil) { (status: OSStatus, infoFlags: VTDecodeInfoFlags, imageBuffer: CVImageBuffer?, taggedBuffers: [CMTaggedBuffer]?, presentationTimeStamp: CMTime, presentationDuration: CMTime) in
            //print(status, infoFlags, imageBuffer, taggedBuffers, presentationTimeStamp, presentationDuration)
            //print("status: \(status), image_nil?: \(imageBuffer == nil), infoFlags: \(infoFlags)")

            callback(imageBuffer)
        }
        if err != 0 {
            //fatalError("VTDecompressionSessionDecodeFrame")
        }
    }
}
