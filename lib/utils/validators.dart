import 'constants.dart';

/// 📝 입력 검증 유틸리티 클래스
/// Form에서 사용하는 validator 함수들을 모아놓은 클래스
class Validators {
  // ✉️ 이메일 검증
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이메일을 입력해주세요';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return '올바른 이메일 형식이 아닙니다';
    }
    
    return null;
  }
  
  // 🔒 비밀번호 검증
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }
    
    if (value.length < AppConstants.minPasswordLength) {
      return '비밀번호는 최소 ${AppConstants.minPasswordLength}자 이상이어야 합니다';
    }
    
    return null;
  }
  
  // 🔒 강력한 비밀번호 검증 (옵션)
  static String? strongPassword(String? value) {
    final basicCheck = password(value);
    if (basicCheck != null) return basicCheck;
    
    if (!RegExp(r'[A-Z]').hasMatch(value!)) {
      return '대문자를 최소 1개 포함해야 합니다';
    }
    
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return '소문자를 최소 1개 포함해야 합니다';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return '숫자를 최소 1개 포함해야 합니다';
    }
    
    return null;
  }
  
  // 🔒 비밀번호 확인 검증
  static String? Function(String?) passwordConfirm(String originalPassword) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return '비밀번호 확인을 입력해주세요';
      }
      
      if (value != originalPassword) {
        return '비밀번호가 일치하지 않습니다';
      }
      
      return null;
    };
  }
  
  // 👤 이름 검증
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이름을 입력해주세요';
    }
    
    if (value.trim().length < 2) {
      return '이름은 최소 2자 이상이어야 합니다';
    }
    
    if (value.length > AppConstants.maxNameLength) {
      return '이름은 최대 ${AppConstants.maxNameLength}자까지 입력 가능합니다';
    }
    
    return null;
  }
  
  // 📱 전화번호 검증 (한국)
  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '전화번호를 입력해주세요';
    }
    
    // 하이픈 제거
    final cleanNumber = value.replaceAll('-', '').replaceAll(' ', '');
    
    // 한국 휴대폰 번호 패턴
    final phoneRegex = RegExp(r'^01[016789]\d{7,8}$');
    
    if (!phoneRegex.hasMatch(cleanNumber)) {
      return '올바른 전화번호 형식이 아닙니다 (예: 010-1234-5678)';
    }
    
    return null;
  }
  
  // 📱 전화번호 검증 (선택)
  static String? phoneNumberOptional(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // 선택 항목이므로 빈 값 허용
    }
    
    return phoneNumber(value);
  }
  
  // 💰 금액 검증
  static String? amount(String? value, {int? min, int? max}) {
    if (value == null || value.trim().isEmpty) {
      return '금액을 입력해주세요';
    }
    
    final cleanValue = value.replaceAll(',', '').replaceAll('원', '').trim();
    final amount = int.tryParse(cleanValue);
    
    if (amount == null) {
      return '올바른 금액을 입력해주세요';
    }
    
    if (amount < 0) {
      return '금액은 0원 이상이어야 합니다';
    }
    
    if (min != null && amount < min) {
      return '최소 금액은 ${min.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}원입니다';
    }
    
    if (max != null && amount > max) {
      return '최대 금액은 ${max.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}원입니다';
    }
    
    return null;
  }
  
  // 🔢 숫자 검증
  static String? number(String? value, {int? min, int? max}) {
    if (value == null || value.trim().isEmpty) {
      return '숫자를 입력해주세요';
    }
    
    final number = int.tryParse(value.trim());
    
    if (number == null) {
      return '올바른 숫자를 입력해주세요';
    }
    
    if (min != null && number < min) {
      return '최소값은 $min입니다';
    }
    
    if (max != null && number > max) {
      return '최대값은 $max입니다';
    }
    
    return null;
  }
  
  // 🔢 숫자 검증 (선택)
  static String? numberOptional(String? value, {int? min, int? max}) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    
    return number(value, min: min, max: max);
  }
  
  // 📝 일반 텍스트 검증 (필수)
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null 
          ? '$fieldName을(를) 입력해주세요'
          : '필수 입력 항목입니다';
    }
    
    return null;
  }
  
  // 📏 길이 검증
  static String? length(
    String? value, {
    int? min,
    int? max,
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return required(value, fieldName: fieldName);
    }
    
    if (min != null && value.length < min) {
      return fieldName != null
          ? '$fieldName은(는) 최소 $min자 이상이어야 합니다'
          : '최소 $min자 이상 입력해주세요';
    }
    
    if (max != null && value.length > max) {
      return fieldName != null
          ? '$fieldName은(는) 최대 $max자까지 입력 가능합니다'
          : '최대 $max자까지 입력 가능합니다';
    }
    
    return null;
  }
  
  // 🔗 URL 검증
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'URL을 입력해주세요';
    }
    
    try {
      final uri = Uri.parse(value.trim());
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return '올바른 URL 형식이 아닙니다 (http:// 또는 https://로 시작)';
      }
      
      if (!uri.hasAuthority) {
        return '올바른 URL 형식이 아닙니다';
      }
      
      return null;
    } catch (e) {
      return '올바른 URL 형식이 아닙니다';
    }
  }
  
  // 🔗 URL 검증 (선택)
  static String? urlOptional(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    
    return url(value);
  }
  
  // 🎨 HEX 색상 코드 검증
  static String? hexColor(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '색상 코드를 입력해주세요';
    }
    
    final hexRegex = RegExp(r'^#?([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$');
    
    if (!hexRegex.hasMatch(value.trim())) {
      return '올바른 색상 코드가 아닙니다 (예: #2E7D32)';
    }
    
    return null;
  }
  
  // ⚽ 백번호 검증
  static String? jerseyNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '등번호를 입력해주세요';
    }
    
    final number = int.tryParse(value.trim());
    
    if (number == null) {
      return '올바른 숫자를 입력해주세요';
    }
    
    if (number < 0 || number > 99) {
      return '등번호는 0~99 사이여야 합니다';
    }
    
    return null;
  }
  
  // ⚽ 골 수 검증
  static String? goals(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // 골 수는 선택 항목
    }
    
    final goals = int.tryParse(value.trim());
    
    if (goals == null) {
      return '올바른 숫자를 입력해주세요';
    }
    
    if (goals < 0) {
      return '골 수는 0 이상이어야 합니다';
    }
    
    if (goals > AppConstants.maxGoalsPerMatch) {
      return '골 수는 최대 ${AppConstants.maxGoalsPerMatch}개까지 입력 가능합니다';
    }
    
    return null;
  }
  
  // 📅 날짜 검증
  static String? date(DateTime? value, {DateTime? minDate, DateTime? maxDate}) {
    if (value == null) {
      return '날짜를 선택해주세요';
    }
    
    if (minDate != null && value.isBefore(minDate)) {
      return '날짜는 ${minDate.year}년 ${minDate.month}월 ${minDate.day}일 이후여야 합니다';
    }
    
    if (maxDate != null && value.isAfter(maxDate)) {
      return '날짜는 ${maxDate.year}년 ${maxDate.month}월 ${maxDate.day}일 이전이어야 합니다';
    }
    
    return null;
  }
  
  // 🎯 복합 검증 (여러 검증을 조합)
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) {
          return result;
        }
      }
      return null;
    };
  }
  
  // 📝 사용자 정의 검증
  static String? Function(String?) custom(
    bool Function(String?) condition,
    String errorMessage,
  ) {
    return (String? value) {
      if (!condition(value)) {
        return errorMessage;
      }
      return null;
    };
  }
  
  // 🏷️ 팀 이름 검증
  static String? teamName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '팀 이름을 입력해주세요';
    }
    
    if (value.trim().length < 2) {
      return '팀 이름은 최소 2자 이상이어야 합니다';
    }
    
    if (value.length > AppConstants.maxNameLength) {
      return '팀 이름은 최대 ${AppConstants.maxNameLength}자까지 입력 가능합니다';
    }
    
    // 특수문자 제한 (일부 허용)
    final allowedChars = RegExp(r'^[가-힣a-zA-Z0-9\s\-_.()]+$');
    if (!allowedChars.hasMatch(value)) {
      return '팀 이름에 사용할 수 없는 문자가 포함되어 있습니다';
    }
    
    return null;
  }
  
  // 📝 설명 검증
  static String? description(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? '설명을 입력해주세요' : null;
    }
    
    if (value.length > AppConstants.maxDescriptionLength) {
      return '설명은 최대 ${AppConstants.maxDescriptionLength}자까지 입력 가능합니다';
    }
    
    return null;
  }
  
  // 💬 댓글 검증
  static String? comment(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '댓글을 입력해주세요';
    }
    
    if (value.trim().length < 1) {
      return '댓글은 최소 1자 이상이어야 합니다';
    }
    
    if (value.length > AppConstants.maxCommentLength) {
      return '댓글은 최대 ${AppConstants.maxCommentLength}자까지 입력 가능합니다';
    }
    
    return null;
  }
}