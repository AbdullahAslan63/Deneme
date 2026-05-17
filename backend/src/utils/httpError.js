/**
 * Controller / service katmanında HTTP durum kodu ile hata fırlatmak için.
 * errorHandler `statusCode` alanını okur.
 */
export class HttpError extends Error {
  constructor(statusCode, message) {
    super(message);
    this.name = "HttpError";
    this.statusCode = statusCode;
  }
}
