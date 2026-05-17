import {
  listExpensesByBuildingService,
  getExpenseSummaryService,
  createExpenseService,
  updateExpenseService,
  deleteExpenseService,
} from "../services/expenseService.js";
import { HttpError } from "../utils/httpError.js";

const handleHttp = (err, res, next) => {
  if (err instanceof HttpError) {
    return res.status(err.statusCode).json({
      success: false,
      message: err.message,
    });
  }
  next(err);
};

export const getExpensesByBuilding = async (req, res, next) => {
  try {
    const { id: buildingId } = req.params;
    const { month, year, category } = req.query;
    const data = await listExpensesByBuildingService(buildingId, req.user.id, {
      month,
      year,
      category,
    });
    res.status(200).json({ success: true, data });
  } catch (err) {
    handleHttp(err, res, next);
  }
};

export const getExpenseSummary = async (req, res, next) => {
  try {
    const { id: buildingId } = req.params;
    const { month, year } = req.query;
    const data = await getExpenseSummaryService(buildingId, req.user.id, {
      month,
      year,
    });
    res.status(200).json({ success: true, data });
  } catch (err) {
    handleHttp(err, res, next);
  }
};

export const createExpense = async (req, res, next) => {
  try {
    const { id: buildingId } = req.params;
    const data = await createExpenseService(buildingId, req.user.id, req.body);
    res.status(201).json({
      success: true,
      message: "Gider kaydedildi.",
      data,
    });
  } catch (err) {
    handleHttp(err, res, next);
  }
};

export const updateExpense = async (req, res, next) => {
  try {
    const data = await updateExpenseService(
      req.params.expenseId,
      req.user.id,
      req.body
    );
    res.status(200).json({
      success: true,
      message: "Gider güncellendi.",
      data,
    });
  } catch (err) {
    handleHttp(err, res, next);
  }
};

export const deleteExpense = async (req, res, next) => {
  try {
    const data = await deleteExpenseService(req.params.expenseId, req.user.id);
    res.status(200).json({
      success: true,
      message: "Gider silindi.",
      data,
    });
  } catch (err) {
    handleHttp(err, res, next);
  }
};
