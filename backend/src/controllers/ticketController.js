import {
  listTicketsByBuildingService,
  listMyTicketsService,
  getTicketByIdService,
  createTicketService,
  addTicketUpdateService,
  changeTicketStatusService,
} from "../services/ticketService.js";
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

export const getTicketsByBuilding = async (req, res, next) => {
  try {
    const { id: buildingId } = req.params;
    const { status, category } = req.query;
    const data = await listTicketsByBuildingService(buildingId, req.user.id, {
      status,
      category,
    });
    res.status(200).json({ success: true, data });
  } catch (err) {
    handleHttp(err, res, next);
  }
};

export const getMyTickets = async (req, res, next) => {
  try {
    const { status, category } = req.query;
    const data = await listMyTicketsService(req.user.id, { status, category });
    res.status(200).json({ success: true, data });
  } catch (err) {
    handleHttp(err, res, next);
  }
};

export const getTicketById = async (req, res, next) => {
  try {
    const data = await getTicketByIdService(req.params.ticketId, req.user);
    res.status(200).json({ success: true, data });
  } catch (err) {
    handleHttp(err, res, next);
  }
};

export const createTicket = async (req, res, next) => {
  try {
    const { apartmentId } = req.params;
    const data = await createTicketService(apartmentId, req.user.id, req.body);
    res.status(201).json({
      success: true,
      message: "Talep oluşturuldu.",
      data,
    });
  } catch (err) {
    handleHttp(err, res, next);
  }
};

export const addTicketUpdate = async (req, res, next) => {
  try {
    const ticket = await addTicketUpdateService(
      req.params.ticketId,
      req.user.id,
      req.body.message
    );
    res.status(201).json({
      success: true,
      message: "Güncelleme eklendi.",
      data: ticket,
    });
  } catch (err) {
    handleHttp(err, res, next);
  }
};

export const patchTicketStatus = async (req, res, next) => {
  try {
    const data = await changeTicketStatusService(
      req.params.ticketId,
      req.user.id,
      req.body.status
    );
    res.status(200).json({
      success: true,
      message: "Talep durumu güncellendi.",
      data,
    });
  } catch (err) {
    handleHttp(err, res, next);
  }
};
