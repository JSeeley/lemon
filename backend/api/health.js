export default function handler(req, res) {
  res.status(200).json({
    status: 'healthy',
    service: 'Lemon Travel API',
    timestamp: new Date().toISOString()
  });
}