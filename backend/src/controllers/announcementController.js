import { sendBuildingAnnouncementService } from "../services/announcementService.js";
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

export const postBuildingAnnouncement = async (req, res, next) => {
  try {
    const { id: buildingId } = req.params;
    const data = await sendBuildingAnnouncementService(
      buildingId,
      req.user.id,
      req.body
    );

    res.status(201).json({
      success: true,
      message:
        data.created > 0
          ? `${data.created} sakine duyuru gönderildi.`
          : "Bu binada kayıtlı sakin bulunamadı.",
      data,
    });
  } catch (err) {
    handleHttp(err, res, next);
  }
};
