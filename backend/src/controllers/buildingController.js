import {
  createBuildingService,
  getBuildingsService,
  getBuildingByIdService,
  updateBuildingService,
  deleteBuildingService,
} from "../services/buildingService.js";

// CREATE
export const createBuilding = async (req, res, next) => {
  try {
    const { name, address, city, totalFloors, apartmentsPerFloor, dueAmount, dueDay, currency } = req.body;

    const managerId = req.user.id; // JWT'den geliyor

    const building = await createBuildingService({
      name,
      address,
      city,
      totalFloors,
      apartmentsPerFloor,
      dueAmount,
      dueDay,
      currency,
      managerId,
    });

    res.status(201).json({
      success: true,
      message: "Bina, daireler ve aidatlar başarıyla oluşturuldu.",
      data: building,
    });
  } catch (error) {
    next(error);
  }
};

// GET ALL
export const getBuildings = async (req, res, next) => {
  try {
    const managerId = req.user.id;

    const buildings = await getBuildingsService(managerId);

    res.json({
      success: true,
      data: buildings,
    });
  } catch (error) {
    next(error);
  }
};

// GET BY ID
export const getBuildingById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const managerId = req.user.id;

    const building = await getBuildingByIdService(id, managerId);

    if (!building) {
      return res.status(404).json({
        success: false,
        message: "Bina bulunamadı",
      });
    }

    res.json({
      success: true,
      data: building,
    });
  } catch (error) {
    next(error);
  }
};

// UPDATE
export const updateBuilding = async (req, res, next) => {
  try {
    const { id } = req.params;
    const managerId = req.user.id;

    const updated = await updateBuildingService(id, managerId, req.body);

    if (!updated) {
      return res.status(404).json({
        success: false,
        message: "Bina bulunamadı",
      });
    }

    res.json({
      success: true,
      data: updated,
    });
  } catch (error) {
    next(error);
  }
};

// DELETE
export const deleteBuilding = async (req, res, next) => {
  try {
    const { id } = req.params;
    const managerId = req.user.id;

    const deleted = await deleteBuildingService(id, managerId);

    if (!deleted) {
      return res.status(404).json({
        success: false,
        message: "Bina bulunamadı",
      });
    }

    res.json({
      success: true,
      message: "Bina silindi",
    });
  } catch (error) {
    next(error);
  }
};