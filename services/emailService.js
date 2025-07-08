const nodemailer = require('nodemailer');
const logger = require('../utils/logger');

class EmailService {
  constructor() {
    this.transporter = null;
    this.isConfigured = false;
    this.initializeTransporter();
  }

  initializeTransporter() {
    // Check if email configuration is provided
    const emailConfig = {
      service: process.env.EMAIL_SERVICE || 'gmail',
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
      from: process.env.EMAIL_FROM || 'Food Truck Finder <noreply@foodtruckfinder.com>'
    };

    if (!emailConfig.user || !emailConfig.pass) {
      logger.warn('Email service not configured. Email functionality will be disabled.');
      return;
    }

    try {
      this.transporter = nodemailer.createTransporter({
        service: emailConfig.service,
        auth: {
          user: emailConfig.user,
          pass: emailConfig.pass
        }
      });

      this.from = emailConfig.from;
      this.isConfigured = true;
      logger.info('Email service initialized successfully');
    } catch (error) {
      logger.error('Failed to initialize email service:', error);
    }
  }

  async sendEmail(options) {
    if (!this.isConfigured) {
      logger.warn('Email service not configured. Skipping email send.');
      return { success: false, message: 'Email service not configured' };
    }

    try {
      const mailOptions = {
        from: this.from,
        ...options
      };

      const result = await this.transporter.sendMail(mailOptions);
      logger.info(`Email sent successfully to ${options.to}`);
      return { success: true, messageId: result.messageId };
    } catch (error) {
      logger.error('Failed to send email:', error);
      return { success: false, error: error.message };
    }
  }

  // Welcome email for new users
  async sendWelcomeEmail(user) {
    const subject = 'Welcome to Food Truck Finder!';
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #FF6B6B;">Welcome to Food Truck Finder, ${user.name}!</h1>
        <p>Thank you for joining our community of food truck enthusiasts!</p>
        
        ${user.role === 'customer' ? `
          <p>As a customer, you can:</p>
          <ul>
            <li>Discover amazing food trucks near you</li>
            <li>Save your favorite trucks</li>
            <li>Leave reviews and ratings</li>
            <li>Get notifications when your favorite trucks are nearby</li>
          </ul>
        ` : `
          <p>As a food truck owner, you can:</p>
          <ul>
            <li>Manage your truck's profile and menu</li>
            <li>Update your location in real-time</li>
            <li>Connect with customers</li>
            <li>Track analytics and insights</li>
            <li>Integrate with social media</li>
          </ul>
        `}
        
        <p>Get started by opening the app and exploring!</p>
        
        <p style="margin-top: 30px; color: #666;">
          Best regards,<br>
          The Food Truck Finder Team
        </p>
      </div>
    `;

    return this.sendEmail({
      to: user.email,
      subject,
      html
    });
  }

  // Password reset email
  async sendPasswordResetEmail(user, resetToken) {
    const resetUrl = `${process.env.FRONTEND_URL || 'https://app.foodtruckfinder.com'}/reset-password?token=${resetToken}`;
    
    const subject = 'Password Reset Request - Food Truck Finder';
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #FF6B6B;">Password Reset Request</h1>
        <p>Hi ${user.name},</p>
        <p>We received a request to reset your password. Click the button below to create a new password:</p>
        
        <div style="text-align: center; margin: 30px 0;">
          <a href="${resetUrl}" style="background-color: #FF6B6B; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
            Reset Password
          </a>
        </div>
        
        <p>Or copy and paste this link in your browser:</p>
        <p style="word-break: break-all; color: #666;">${resetUrl}</p>
        
        <p>This link will expire in 1 hour for security reasons.</p>
        
        <p>If you didn't request this password reset, please ignore this email.</p>
        
        <p style="margin-top: 30px; color: #666;">
          Best regards,<br>
          The Food Truck Finder Team
        </p>
      </div>
    `;

    return this.sendEmail({
      to: user.email,
      subject,
      html
    });
  }

  // Email change notification
  async sendEmailChangeNotification(oldEmail, newEmail, userName) {
    const subject = 'Email Address Changed - Food Truck Finder';
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #FF6B6B;">Email Address Changed</h1>
        <p>Hi ${userName},</p>
        <p>Your email address has been successfully changed from <strong>${oldEmail}</strong> to <strong>${newEmail}</strong>.</p>
        
        <p>If you didn't make this change, please contact our support team immediately.</p>
        
        <p style="margin-top: 30px; color: #666;">
          Best regards,<br>
          The Food Truck Finder Team
        </p>
      </div>
    `;

    // Send to both old and new email addresses
    await this.sendEmail({
      to: oldEmail,
      subject,
      html
    });

    return this.sendEmail({
      to: newEmail,
      subject,
      html
    });
  }

  // Review notification for truck owners
  async sendNewReviewNotification(owner, truck, review) {
    const subject = `New ${review.rating}-star review for ${truck.name}`;
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #FF6B6B;">New Review for ${truck.name}</h1>
        <p>Hi ${owner.name},</p>
        <p>You've received a new review!</p>
        
        <div style="background-color: #f5f5f5; padding: 20px; border-radius: 10px; margin: 20px 0;">
          <p><strong>Rating:</strong> ${'⭐'.repeat(review.rating)} (${review.rating}/5)</p>
          <p><strong>From:</strong> ${review.userName}</p>
          <p><strong>Comment:</strong></p>
          <p style="font-style: italic;">"${review.comment}"</p>
        </div>
        
        <p>Log in to your dashboard to respond to this review and engage with your customers.</p>
        
        <p style="margin-top: 30px; color: #666;">
          Best regards,<br>
          The Food Truck Finder Team
        </p>
      </div>
    `;

    return this.sendEmail({
      to: owner.email,
      subject,
      html
    });
  }

  // Daily digest for truck owners
  async sendDailyDigest(owner, stats) {
    const subject = `Daily Report - ${new Date().toLocaleDateString()}`;
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #FF6B6B;">Your Daily Report</h1>
        <p>Hi ${owner.name},</p>
        <p>Here's your daily summary for ${stats.truckName}:</p>
        
        <div style="background-color: #f5f5f5; padding: 20px; border-radius: 10px; margin: 20px 0;">
          <h3>Today's Performance</h3>
          <p><strong>Profile Views:</strong> ${stats.views || 0}</p>
          <p><strong>New Favorites:</strong> ${stats.newFavorites || 0}</p>
          <p><strong>Total Favorites:</strong> ${stats.totalFavorites || 0}</p>
          <p><strong>New Reviews:</strong> ${stats.newReviews || 0}</p>
          <p><strong>Average Rating:</strong> ${stats.averageRating || 'N/A'} ⭐</p>
        </div>
        
        ${stats.topPerformingItem ? `
          <p><strong>Most Popular Menu Item:</strong> ${stats.topPerformingItem}</p>
        ` : ''}
        
        <p>Keep up the great work!</p>
        
        <p style="margin-top: 30px; color: #666;">
          Best regards,<br>
          The Food Truck Finder Team
        </p>
      </div>
    `;

    return this.sendEmail({
      to: owner.email,
      subject,
      html
    });
  }
}

// Export singleton instance
module.exports = new EmailService();