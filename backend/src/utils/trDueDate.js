const ISTANBUL_TZ = "Europe/Istanbul";

/**
 * Verilen anın İstanbul takvimindeki yıl ve ayı (ay 1–12).
 * @param {Date} [now=new Date()]
 */
export function getIstanbulYearMonth(now = new Date()) {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone: ISTANBUL_TZ,
    year: "numeric",
    month: "numeric",
  });
  const parts = formatter.formatToParts(now);
  const year = Number(parts.find((p) => p.type === "year")?.value);
  const month = Number(parts.find((p) => p.type === "month")?.value);
  if (!Number.isFinite(year) || !Number.isFinite(month)) {
    const d = new Date(now);
    return { year: d.getFullYear(), month: d.getMonth() + 1 };
  }
  return { year, month };
}

/**
 * Aidat son günü: takvimdeki günün sonu, **İstanbul (TRT = UTC+3, yaz saati yok)**.
 * Prisma `DateTime` UTC saklar; bu fonksiyon o günün 23:59:59.999 TRT anına denk gelen anı döndürür.
 *
 * @param {number} calendarYear
 * @param {number} calendarMonth 1–12
 * @param {number} dueDay ayın günü (şemada 1–28)
 */
export function endOfDueDayIstanbul(calendarYear, calendarMonth, dueDay) {
  const monthIndex = calendarMonth - 1;
  return new Date(Date.UTC(calendarYear, monthIndex, dueDay, 20, 59, 59, 999));
}
