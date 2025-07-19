const sharp = require('sharp');
const path = require('path');
const fs = require('fs').promises;

class ImageProcessingService {
  
  // Process and optimize image before upload
  static async processImage(inputBuffer, options = {}) {
    const {
      width = 1200,
      height = 600,
      quality = 80,
      format = 'jpeg'
    } = options;

    try {
      const processedBuffer = await sharp(inputBuffer)
        .resize(width, height, { 
          fit: 'cover',
          position: 'center'
        })
        .jpeg({ 
          quality,
          progressive: true,
          mozjpeg: true
        })
        .toBuffer();

      return processedBuffer;
    } catch (error) {
      throw new Error(`Image processing failed: ${error.message}`);
    }
  }

  // Generate multiple sizes for responsive images
  static async generateResponsiveSizes(inputBuffer) {
    const sizes = [
      { width: 1200, height: 600, suffix: 'xl' },
      { width: 800, height: 400, suffix: 'lg' },
      { width: 400, height: 200, suffix: 'md' },
      { width: 200, height: 100, suffix: 'sm' }
    ];

    const processedImages = {};

    for (const size of sizes) {
      try {
        const processed = await sharp(inputBuffer)
          .resize(size.width, size.height, { 
            fit: 'cover',
            position: 'center'
          })
          .jpeg({ 
            quality: 80,
            progressive: true
          })
          .toBuffer();

        processedImages[size.suffix] = processed;
      } catch (error) {
        console.error(`Failed to process ${size.suffix} size:`, error);
      }
    }

    return processedImages;
  }

  // Extract image metadata
  static async getImageMetadata(inputBuffer) {
    try {
      const metadata = await sharp(inputBuffer).metadata();
      return {
        width: metadata.width,
        height: metadata.height,
        format: metadata.format,
        size: metadata.size,
        density: metadata.density,
        hasAlpha: metadata.hasAlpha
      };
    } catch (error) {
      throw new Error(`Failed to extract metadata: ${error.message}`);
    }
  }

  // Validate image dimensions and file size
  static validateImage(metadata, options = {}) {
    const {
      maxWidth = 4000,
      maxHeight = 4000,
      minWidth = 200,
      minHeight = 100,
      maxFileSize = 10 * 1024 * 1024, // 10MB
      allowedFormats = ['jpeg', 'jpg', 'png', 'webp']
    } = options;

    const errors = [];

    if (metadata.width > maxWidth) {
      errors.push(`Image width (${metadata.width}px) exceeds maximum (${maxWidth}px)`);
    }

    if (metadata.height > maxHeight) {
      errors.push(`Image height (${metadata.height}px) exceeds maximum (${maxHeight}px)`);
    }

    if (metadata.width < minWidth) {
      errors.push(`Image width (${metadata.width}px) is below minimum (${minWidth}px)`);
    }

    if (metadata.height < minHeight) {
      errors.push(`Image height (${metadata.height}px) is below minimum (${minHeight}px)`);
    }

    if (metadata.size > maxFileSize) {
      errors.push(`File size (${Math.round(metadata.size / 1024 / 1024)}MB) exceeds maximum (${Math.round(maxFileSize / 1024 / 1024)}MB)`);
    }

    if (!allowedFormats.includes(metadata.format.toLowerCase())) {
      errors.push(`Format ${metadata.format} not allowed. Supported: ${allowedFormats.join(', ')}`);
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  // Create thumbnail
  static async createThumbnail(inputBuffer, size = 150) {
    try {
      return await sharp(inputBuffer)
        .resize(size, size, { 
          fit: 'cover',
          position: 'center'
        })
        .jpeg({ quality: 70 })
        .toBuffer();
    } catch (error) {
      throw new Error(`Thumbnail creation failed: ${error.message}`);
    }
  }

}

module.exports = ImageProcessingService;
