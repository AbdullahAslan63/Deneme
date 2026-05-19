import {
  getApartmentsService,
  createApartmentService,
  deleteApartmentService,
  updateApartmentService,
  removeResidentFromApartmentService,
} from "../services/apartmentService.js";

// GET /api/v1/buildings/:buildingId/apartments
export const getApartments = async (req, res, next) => {
  try {
    const { buildingId } = req.params;
    const managerId = req.user.id;

    const apartments = await getApartmentsService(buildingId, managerId);

    if (!apartments) {
      return res.status(403).json({
        success: false,
        message: "Bu binanın dairelerini görüntüleme yetkiniz yok.",
      });
    }

    res.status(200).json({
      success: true,
      data: apartments,
    });
  } catch (error) {
    next(error);
  }
};

// POST /api/v1/buildings/:buildingId/apartments
export const createApartment = async (req, res, next) => {
  try {
    const { buildingId } = req.params;
    const { number, floor } = req.body;
    const managerId = req.user.id;

    if (!number) {
      return res.status(400).json({
        success: false,
        message: "Daire numarası zorunludur.",
      });
    }

    const apartment = await createApartmentService({
      buildingId,
      number: number.trim(),
      floor: floor ? Number(floor) : null,
      managerId,
    });

    if (!apartment) {
      return res.status(403).json({
        success: false,
        message: "Bu binaya daire ekleme yetkiniz yok.",
      });
    }

    res.status(201).json({
      success: true,
      message: "Daire başarıyla oluşturuldu.",
      data: apartment,
    });
  } catch (error) {
    next(error);
  }
};

// DELETE /api/v1/buildings/:buildingId/apartments/:id/resident
export const removeResidentFromApartment = async (req, res, next) => {
  try {
    const { buildingId, id } = req.params;
    const managerId = req.user.id;

    const result = await removeResidentFromApartmentService(id, buildingId, managerId);

    if (result.forbidden) {
      return res.status(403).json({
        success: false,
        message: "Bu işlem için yetkiniz yok.",
      });
    }
    if (result.notFound) {
      return res.status(404).json({
        success: false,
        message: "Daire bulunamadı.",
      });
    }
    if (result.noResident) {
      return res.status(404).json({
        success: false,
        message: "Bu dairede kayıtlı sakin yok.",
      });
    }

    res.status(200).json({
      success: true,
      message: "Sakin daireden ayrıldı.",
      data: result.apartment,
    });
  } catch (error) {
    next(error);
  }
};

// DELETE /api/v1/buildings/:buildingId/apartments/:id
export const deleteApartment = async (req, res, next) => {
  try {
    const { buildingId, id } = req.params;
    const managerId = req.user.id;

    const deleted = await deleteApartmentService(id, buildingId, managerId);

    if (!deleted) {
      return res.status(404).json({
        success: false,
        message: "Daire bulunamadı veya silme yetkiniz yok.",
      });
    }

    res.status(200).json({
      success: true,
      message: "Daire silindi.",
    });
  } catch (error) {
    next(error);
  }
};

// PUT /api/v1/buildings/:buildingId/apartments/:id
export const updateApartment = async (req, res, next) => {
  try {
    const { buildingId, id } = req.params;
    const { number, floor } = req.body;
    const managerId = req.user.id;

    const updateData = {};
    if (number !== undefined) updateData.number = number.trim();
    if (floor !== undefined) updateData.floor = Number(floor);

    const apartment = await updateApartmentService(id, buildingId, managerId, updateData);

    if (!apartment) {
      return res.status(404).json({
        success: false,
        message: "Daire bulunamadı veya güncelleme yetkiniz yok.",
      });
    }

    res.status(200).json({
      success: true,
      message: "Daire başarıyla güncellendi.",
      data: apartment,
    });
  } catch (error) {
    next(error);
  }
};