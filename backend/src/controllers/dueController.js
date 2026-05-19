import {
  getDuesByBuildingService,
  updateDueStatusService,
  getMyDuesService,
  updateBuildingDueAmountService,
} from "../services/dueService.js";

/**
 * GET /api/v1/buildings/:id/dues
 * Yönetici: Binadaki tüm aidatları listele
 */
export const getDuesByBuilding = async (req, res, next) => {
  try {
    const { id: buildingId } = req.params;
    const { month, year, status } = req.query;
    const managerId = req.user.id;

    const dues = await getDuesByBuildingService(buildingId, managerId, { month, year, status });

    if (dues === null) {
      return res.status(404).json({
        success: false,
        message: "Bina bulunamadı veya erişim yetkiniz yok.",
      });
    }

    res.json({
      success: true,
      data: dues,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PATCH /api/v1/buildings/:id/dues/:dueId/status
 * Yönetici: Aidat durumunu güncelle
 */
export const updateDueStatus = async (req, res, next) => {
  try {
    const { id: buildingId, dueId } = req.params;
    const { status, paidAt, note } = req.body;
    const managerId = req.user.id;

    const result = await updateDueStatusService(dueId, managerId, {
      status,
      paidAt,
      note,
      buildingId,
    });

    if (result === null) {
      return res.status(404).json({
        success: false,
        message: "Aidat kaydı bulunamadı.",
      });
    }

    if (result.forbidden) {
      return res.status(403).json({
        success: false,
        message: "Bu aidat kaydını güncelleme yetkiniz yok.",
      });
    }

    res.json({
      success: true,
      message: "Aidat durumu güncellendi.",
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/v1/me/dues
 * Sakin: Kendi aidatlarını listele
 */
export const getMyDues = async (req, res, next) => {
  try {
    const { status, year, month } = req.query;
    const userId = req.user.id;

    const dues = await getMyDuesService(userId, { status, year, month });

    res.json({
      success: true,
      data: dues,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PATCH /api/v1/buildings/:id/due-amount
 * Yönetici: Aidat bedelini güncelle
 */
export const updateBuildingDueAmount = async (req, res, next) => {
  try {
    const { id: buildingId } = req.params;
    const { dueAmount, dueDay, currency, affectCurrent } = req.body;
    const managerId = req.user.id;

    const result = await updateBuildingDueAmountService(buildingId, managerId, {
      dueAmount,
      dueDay,
      currency,
      affectCurrent,
    });

    if (result === null) {
      return res.status(404).json({
        success: false,
        message: "Bina bulunamadı veya erişim yetkiniz yok.",
      });
    }

    res.json({
      success: true,
      message: "Aidat bedeli güncellendi.",
      data: result,
    });
  } catch (error) {
    next(error);
  }
};
