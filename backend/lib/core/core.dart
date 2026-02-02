/// Core module exports
library core;

// Supabase
export 'package:supabase/supabase.dart' show AuthException;

// Errors
export 'errors/failures.dart';
export 'errors/result.dart';

// Use Cases
export 'usecases/usecase.dart';

// Utils
export 'utils/auth_utils.dart';
export 'utils/supabase_client.dart';
export 'utils/validators.dart';
export 'utils/logger.dart';
