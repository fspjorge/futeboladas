import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

class MockSupabaseStreamFilterBuilder extends Mock
    implements SupabaseStreamFilterBuilder {}

// Helper to setup a basic chain
void setupSupabaseFluentMock(
  MockSupabaseClient client, {
  required String table,
  MockSupabaseQueryBuilder? queryBuilder,
  MockPostgrestFilterBuilder? filterBuilder,
}) {
  final qb = queryBuilder ?? MockSupabaseQueryBuilder();
  // final fb = filterBuilder ?? MockPostgrestFilterBuilder();

  when(() => client.from(table)).thenReturn(qb);
}
