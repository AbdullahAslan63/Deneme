/** Bildirim başlık/gövde şablonları — tek kaynak (A12). */

export const TICKET_CREATED_MANAGER = {
  title: "Yeni talep",
  body: (apartmentNumber, ticketTitle) =>
    `Daire ${apartmentNumber}: ${ticketTitle}`,
};

export const TICKET_UPDATE_NOTE = {
  title: "Talebiniz güncellendi",
  body: (preview) => `Yöneticiniz talebinize not ekledi: ${preview}`,
};

export const DUE_PAID_RESIDENT = {
  title: "Aidatınız ödendi",
  body: (month, year) =>
    `${month}/${year} dönemi aidatınız ödendi olarak işaretlendi.`,
};

export const DUE_REMINDER_RESIDENT = {
  title: "Aidat hatırlatması",
  body: (month, year, amount, currency) =>
    `${month}/${year} dönemi aidatınız (${amount} ${currency}) henüz ödenmemiştir.`,
};
