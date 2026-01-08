export const serviceAuth = (req, res, next) => {
  const apiKey = req.headers['x-service-api-key'];
  const secretKey = process.env.SERVICE_API_KEY || 'kyte2026AgentKeyX777';

  if (!apiKey || apiKey !== secretKey) {
    return res.status(401).json({ error: 'Unauthorized: Invalid Service API Key' });
  }
  next();
};

