import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import "../../config/config.js"

const s3Client = new S3Client({
    region: process.env.AWS_REGION ,
    credentials: {
      accessKeyId: process.env.AWS_ACCESS_KEY_ID ,
      secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY  ,
    }
  });
  
/**
 * Upload un fichier buffer vers S3 et retourne l'URL publique
 * @param {object} file - req.file provenant de multer
 * @returns {string} URL publique du fichier
 */

export async function uploadFileToS3(file) {
  const bucketName = process.env.S3_BUCKET ;
  const key = `${Date.now()}_${file.originalname}`;

  const params = {
    Bucket: bucketName,
    Key: key,
    Body: file.buffer,
    ContentType: file.mimetype,
  };

  await s3Client.send(new PutObjectCommand(params));

  // Retourne l'URL CloudFront si défini, sinon l'URL S3
  const cloudfrontUrl = process.env.CLOUDFRONT_URL;
  if (cloudfrontUrl) {
    return `${cloudfrontUrl}/${key}`;
  }
  return `https://${bucketName}.s3.${process.env.AWS_REGION}.amazonaws.com/${key}`;
}
