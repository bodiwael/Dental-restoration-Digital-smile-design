import torch
import onnx

"""
MobileSAM to TFLite Conversion Script

This script converts MobileSAM PyTorch models to TFLite format for on-device inference.

Prerequisites:
    pip install mobile-sam torch onnx onnx-tf tensorflow

Usage:
    python convert_mobilesam.py

Outputs:
    - mobile_sam_encoder.tflite (for image encoding, ~22MB)
    - mobile_sam_decoder.tflite (for mask decoding, ~16MB)
"""

def export_encoder():
    """Export the image encoder to ONNX then TFLite"""
    from mobile_sam import sam_model_registry
    
    print("Loading MobileSAM model...")
    model = sam_model_registry["vit_t"](checkpoint="mobile_sam.pt")
    model.eval()
    
    print("Exporting image encoder to ONNX...")
    
    # Create dummy input
    dummy_input = torch.randn(1, 3, 1024, 1024)
    
    # Export to ONNX
    torch.onnx.export(
        model.image_encoder,
        dummy_input,
        "mobile_sam_encoder.onnx",
        opset_version=17,
        input_names=["input_image"],
        output_names=["image_embedding"],
        dynamic_axes={
            "input_image": {0: "batch_size"},
            "image_embedding": {0: "batch_size"}
        }
    )
    
    print("Encoder ONNX exported successfully!")
    print("Converting to TFLite...")
    
    # Convert ONNX to TFLite using onnx-tf
    try:
        import onnx_tf
        import tensorflow as tf
        
        # Load ONNX model
        onnx_model = onnx.load("mobile_sam_encoder.onnx")
        
        # Convert to TensorFlow
        tf_rep = onnx_tf.backend.prepare(onnx_model)
        
        # Export to TensorFlow SavedModel
        tf_rep.export_graph("encoder_tf")
        
        # Convert to TFLite
        converter = tf.lite.TFLiteConverter.from_saved_model("encoder_tf")
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_types = [tf.float16]
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS,
            tf.lite.OpsSet.SELECT_TF_OPS
        ]
        
        tflite_model = converter.convert()
        
        with open("mobile_sam_encoder.tflite", "wb") as f:
            f.write(tflite_model)
        
        print("Encoder TFLite conversion complete!")
        print(f"Model size: {len(tflite_model) / 1024 / 1024:.2f} MB")
        
    except ImportError as e:
        print(f"TFLite conversion failed: {e}")
        print("Please install: pip install onnx-tf tensorflow")
        print("ONNX file saved, manual conversion required")


def export_decoder():
    """Export the mask decoder to ONNX then TFLite"""
    from mobile_sam import sam_model_registry
    
    print("\nLoading MobileSAM model for decoder export...")
    model = sam_model_registry["vit_t"](checkpoint="mobile_sam.pt")
    model.eval()
    
    print("Exporting mask decoder to ONNX...")
    
    # Decoder inputs:
    # - image_embeddings: [1, 256, 64, 64]
    # - point_coords: [1, num_points, 2]
    # - point_labels: [1, num_points]
    # - mask_input: [1, 1, 256, 256]
    # - has_mask_input: [1]
    
    dummy_embedding = torch.randn(1, 256, 64, 64)
    dummy_points = torch.randn(1, 1, 2)
    dummy_labels = torch.randint(0, 2, (1, 1)).float()
    dummy_mask_input = torch.randn(1, 1, 256, 256)
    dummy_has_mask = torch.tensor([False])
    
    # Export to ONNX
    torch.onnx.export(
        model.mask_decoder,
        (dummy_embedding, dummy_points, dummy_labels, dummy_mask_input, dummy_has_mask),
        "mobile_sam_decoder.onnx",
        opset_version=17,
        input_names=[
            "image_embeddings",
            "point_coords", 
            "point_labels",
            "mask_input",
            "has_mask_input"
        ],
        output_names=["masks", "iou_predictions"],
        dynamic_axes={
            "image_embeddings": {0: "batch_size"},
            "point_coords": {0: "batch_size", 1: "num_points"},
            "point_labels": {0: "batch_size", 1: "num_points"},
            "mask_input": {0: "batch_size"},
            "masks": {0: "batch_size"},
            "iou_predictions": {0: "batch_size"}
        }
    )
    
    print("Decoder ONNX exported successfully!")
    print("Converting to TFLite...")
    
    # Convert ONNX to TFLite
    try:
        import onnx_tf
        import tensorflow as tf
        
        # Load ONNX model
        onnx_model = onnx.load("mobile_sam_decoder.onnx")
        
        # Convert to TensorFlow
        tf_rep = onnx_tf.backend.prepare(onnx_model)
        
        # Export to TensorFlow SavedModel
        tf_rep.export_graph("decoder_tf")
        
        # Convert to TFLite
        converter = tf.lite.TFLiteConverter.from_saved_model("decoder_tf")
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_types = [tf.float16]
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS,
            tf.lite.OpsSet.SELECT_TF_OPS
        ]
        
        tflite_model = converter.convert()
        
        with open("mobile_sam_decoder.tflite", "wb") as f:
            f.write(tflite_model)
        
        print("Decoder TFLite conversion complete!")
        print(f"Model size: {len(tflite_model) / 1024 / 1024:.2f} MB")
        
    except ImportError as e:
        print(f"TFLite conversion failed: {e}")
        print("Please install: pip install onnx-tf tensorflow")
        print("ONNX file saved, manual conversion required")


if __name__ == "__main__":
    print("=" * 60)
    print("MobileSAM to TFLite Converter")
    print("=" * 60)
    
    # Check if model file exists
    import os
    if not os.path.exists("mobile_sam.pt"):
        print("\nError: mobile_sam.pt not found!")
        print("Download it from:")
        print("https://github.com/ChaoningZhang/MobileSAM/releases/download/v1.0/mobile_sam.pt")
        exit(1)
    
    # Export encoder
    export_encoder()
    
    # Export decoder
    export_decoder()
    
    print("\n" + "=" * 60)
    print("Conversion complete!")
    print("Copy these files to your Flutter project:")
    print("  cp mobile_sam_encoder.tflite assets/models/")
    print("  cp mobile_sam_decoder.tflite assets/models/")
    print("=" * 60)
