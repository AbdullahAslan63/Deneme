import '../models/invite_code_model.dart';

abstract class InviteCodeRepository {
  Future<InviteCodeModel> generateInviteCode(String apartmentId);
}
