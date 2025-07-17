class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    // Basic email regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    // Check for uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for number
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    // Check for special character
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }
  
  // Name validation
  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters long';
    }
    
    if (value.trim().length > 50) {
      return '$fieldName must be less than 50 characters';
    }
    
    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value)) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }
  
  // Business name validation
  static String? validateBusinessName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Business name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Business name must be at least 2 characters long';
    }
    
    if (value.trim().length > 100) {
      return 'Business name must be less than 100 characters';
    }
    
    return null;
  }
  
  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove all non-numeric characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    // Check if it's a valid US phone number (10 digits)
    if (digitsOnly.length != 10) {
      return 'Please enter a valid 10-digit phone number';
    }
    
    return null;
  }
  
  // Price validation
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    
    final price = double.tryParse(value);
    if (price == null) {
      return 'Please enter a valid price';
    }
    
    if (price < 0) {
      return 'Price cannot be negative';
    }
    
    if (price > 9999.99) {
      return 'Price must be less than \$10,000';
    }
    
    return null;
  }
  
  // Description validation
  static String? validateDescription(String? value, {int maxLength = 500}) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }
    
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters long';
    }
    
    if (value.length > maxLength) {
      return 'Description must be less than $maxLength characters';
    }
    
    return null;
  }
  
  // Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    
    if (value.trim().length < 10) {
      return 'Please enter a complete address';
    }
    
    if (value.trim().length > 200) {
      return 'Address must be less than 200 characters';
    }
    
    return null;
  }
  
  // Website URL validation
  static String? validateWebsite(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Website is optional
    }
    
    // Add http:// if no protocol is specified
    String url = value;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    
    // Basic URL validation
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)+([/?].*)?$',
    );
    
    if (!urlRegex.hasMatch(url)) {
      return 'Please enter a valid website URL';
    }
    
    return null;
  }
  
  // Time validation (HH:MM format)
  static String? validateTime(String? value) {
    if (value == null || value.isEmpty) {
      return 'Time is required';
    }
    
    final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    
    if (!timeRegex.hasMatch(value)) {
      return 'Please enter time in HH:MM format';
    }
    
    return null;
  }
  
  // Cuisine type validation
  static String? validateCuisine(String? value) {
    if (value == null || value.isEmpty) {
      return 'Cuisine type is required';
    }
    
    if (value.trim().length < 3) {
      return 'Cuisine type must be at least 3 characters';
    }
    
    if (value.trim().length > 50) {
      return 'Cuisine type must be less than 50 characters';
    }
    
    return null;
  }
  
  // Menu item name validation
  static String? validateMenuItemName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Menu item name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (value.trim().length > 100) {
      return 'Name must be less than 100 characters';
    }
    
    return null;
  }
  
  // Category validation
  static String? validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Category is optional
    }
    
    if (value.trim().length > 50) {
      return 'Category must be less than 50 characters';
    }
    
    return null;
  }
  
  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  // Credit card validation (basic)
  static String? validateCreditCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }
    
    // Remove spaces and dashes
    final cardNumber = value.replaceAll(RegExp(r'[\s-]'), '');
    
    // Check if it contains only digits
    if (!RegExp(r'^\d+$').hasMatch(cardNumber)) {
      return 'Card number can only contain digits';
    }
    
    // Check length (most cards are 13-19 digits)
    if (cardNumber.length < 13 || cardNumber.length > 19) {
      return 'Please enter a valid card number';
    }
    
    // Basic Luhn algorithm check
    if (!_isValidLuhn(cardNumber)) {
      return 'Please enter a valid card number';
    }
    
    return null;
  }
  
  // Luhn algorithm for credit card validation
  static bool _isValidLuhn(String cardNumber) {
    int sum = 0;
    bool alternate = false;
    
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return sum % 10 == 0;
  }
  
  // Expiry date validation (MM/YY format)
  static String? validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }
    
    final expiryRegex = RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$');
    
    if (!expiryRegex.hasMatch(value)) {
      return 'Please enter date in MM/YY format';
    }
    
    // Check if the card is not expired
    final parts = value.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse('20${parts[1]}');
    
    final now = DateTime.now();
    final expiry = DateTime(year, month + 1, 0); // Last day of the month
    
    if (expiry.isBefore(now)) {
      return 'Card has expired';
    }
    
    return null;
  }
  
  // CVV validation
  static String? validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }
    
    if (!RegExp(r'^\d{3,4}$').hasMatch(value)) {
      return 'CVV must be 3 or 4 digits';
    }
    
    return null;
  }
  
  // Rating validation
  static String? validateRating(double? value) {
    if (value == null) {
      return 'Rating is required';
    }
    
    if (value < 0 || value > 5) {
      return 'Rating must be between 0 and 5';
    }
    
    return null;
  }
  
  // Sanitize input to prevent XSS
  static String sanitizeInput(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;')
        .replaceAll('&', '&amp;');
  }
} 