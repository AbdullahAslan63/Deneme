import express from "express";
import {
  getApartments,
  createApartment,
  deleteApartment,
  updateApartment,
  removeResidentFromApartment,
} from "../controllers/apartmentController.js";

import { authMiddleware } from "../middlewares/authMiddleware.js";
import { requireRoles } from "../middlewares/roleMiddleware.js";
import { validate, apartmentSchemas } from "../middlewares/validate.js";

const router = express.Router({ mergeParams: true });

router.use(authMiddleware);
router.use(requireRoles("MANAGER"));

router.get("/", validate(apartmentSchemas.getByBuilding), getApartments);
router.post("/", validate(apartmentSchemas.create), createApartment);
router.delete(
  "/:id/resident",
  validate(apartmentSchemas.removeResident),
  removeResidentFromApartment
);
router.put("/:id", validate(apartmentSchemas.update), updateApartment);
router.delete("/:id", validate(apartmentSchemas.delete), deleteApartment);

export default router;