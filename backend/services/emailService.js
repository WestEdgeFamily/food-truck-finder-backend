const nodemailer = require('nodemailer');
const logger = require('../utils/logger');

// Create transporter
const transporter = nodemailer.createTransporter({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: process.env.SMTP_PORT || 587,
  secure: false, // true for 465, false for other ports
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS
  }
});

// Send welcome email
const sendWelcomeEmail = async (user) => {
  try {
    if (!process.env.SMTP_USER || !process.env.SMTP_PASS) {
      logger.warn('Email service not configured - skipping welcome email');
      return;
    }

    const mailOptions = {
      from: `"Food Truck Finder" <${process.env.SMTP_USER}>`,
      to: user.email,
      subject: 'Welcome to Food Truck Finder!',
      html: `
        <h2>Welcome to Food Truck Finder!</h2>
        <p>Hi ${user.name},</p>
        <p>Thank you for joining Food Truck Finder! We're excited to have you on board.</p>
        ${user.role === 'owner' ? `
          <p>As a food truck owner, you can now:</p>
          <ul>
            <li>Manage your food truck profile</li>
            <li>Update your location in real-time</li>
            <li>Manage your menu and pricing</li>
            <li>Track customer reviews and ratings</li>
            <li>View analytics and insights</li>
          </ul>
        ` : `
          <p>As a customer, you can now:</p>
          <ul>
            <li>Find food trucks near you</li>
            <li>Browse menus and pricing</li>
            <li>Add your favorite trucks</li>
            <li>Leave reviews and ratings</li>
            <li>Get notifications about nearby trucks</li>
          </ul>
        `}
        <p>If you have any questions, feel free to reach out to our support team.</p>
        <p>Happy eating!</p>
        <p>The Food Truck Finder Team</p>
      `
    };

    await transporter.sendMail(mailOptions);
    logger.info(`Welcome email sent to ${user.email}`);
  } catch (error) {
    logger.error('Error sending welcome email:', error);
  }
};

// Send password reset email
const sendPasswordResetEmail = async (user, resetToken) => {
  try {
    if (!process.env.SMTP_USER || !process.env.SMTP_PASS) {
      logger.warn('Email service not configured - skipping password reset email');
      return;
    }

    const resetUrl = `${process.env.FRONTEND_URL}/reset-password?token=${resetToken}`;

    const mailOptions = {
      from: `"Food Truck Finder" <${process.env.SMTP_USER}>`,
      to: user.email,
      subject: 'Password Reset Request',
      html: `
        <h2>Password Reset Request</h2>
        <p>Hi ${user.name},</p>
        <p>We received a request to reset your password for your Food Truck Finder account.</p>
        <p>Click the link below to reset your password:</p>
        <p><a href="${resetUrl}" style="background-color: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Reset Password</a></p>
        <p>This link will expire in 1 hour.</p>
        <p>If you didn't request this password reset, you can safely ignore this email.</p>
        <p>The Food Truck Finder Team</p>
      `
    };

    await transporter.sendMail(mailOptions);
    logger.info(`Password reset email sent to ${user.email}`);
  } catch (error) {
    logger.error('Error sending password reset email:', error);
  }
};

module.exports = {
  sendWelcomeEmail,
  sendPasswordResetEmail
};
