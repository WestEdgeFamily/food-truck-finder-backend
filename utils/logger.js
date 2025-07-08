const winston = require('winston');

// Define log levels
const levels = {
  error: 0,
  warn: 1,
  info: 2,
  http: 3,
  debug: 4,
};

// Define log colors
const colors = {
  error: 'red',
  warn: 'yellow',
  info: 'green',
  http: 'magenta',
  debug: 'white',
};

winston.addColors(colors);

// Define log format
const format = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss:ms' }),
  winston.format.colorize({ all: true }),
  winston.format.printf(
    (info) => `${info.timestamp} ${info.level}: ${info.message}`,
  ),
);

// Define which transports the logger must use
const transports = [
  // Console transport for development
  new winston.transports.Console({
    format: winston.format.combine(
      winston.format.colorize(),
      winston.format.simple(),
    ),
  }),
];

// Create the logger
const logger = winston.createLogger({
  level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
  levels,
  format,
  transports,
});

// Create a stream object for Morgan middleware
logger.stream = {
  write: (message) => logger.http(message.trim()),
};

// Export logger with safe methods that won't expose sensitive data in production
module.exports = {
  error: (message, error = null) => {
    if (process.env.NODE_ENV === 'production') {
      // In production, sanitize error messages
      logger.error(message);
      if (error) {
        logger.error(`Error type: ${error.name}`);
      }
    } else {
      // In development, show full error details
      logger.error(message, error);
    }
  },
  warn: (message) => logger.warn(message),
  info: (message) => logger.info(message),
  http: (message) => logger.http(message),
  debug: (message) => {
    // Only log debug messages in non-production environments
    if (process.env.NODE_ENV !== 'production') {
      logger.debug(message);
    }
  },
  stream: logger.stream,
};