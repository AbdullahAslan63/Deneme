/**
 * FCM data alanı — tüm değerler string (PLAN.md / FLUTTER-BACKEND.md sözleşmesi).
 * @param {import("@prisma/client").Notification} notification
 */
export function buildPushData(notification) {
  const fromJson =
    notification.data &&
    typeof notification.data === "object" &&
    !Array.isArray(notification.data)
      ? notification.data
      : {};

  return {
    type: String(notification.type),
    notificationId: String(notification.id),
    ...Object.fromEntries(
      Object.entries(fromJson).map(([k, v]) => [k, v == null ? "" : String(v)])
    ),
  };
}

/** API yanıtı için bildirim satırı (gereksiz alan ekleme). */
export function formatNotificationRow(row) {
  if (!row) return null;
  return {
    id: row.id,
    userId: row.userId,
    title: row.title,
    body: row.body,
    type: row.type,
    isRead: row.isRead,
    data: row.data ?? null,
    createdAt: row.createdAt,
  };
}

/** Liste yanıtı: items, nextCursor, unreadCount */
export function formatNotificationListPage({ items, nextCursor, unreadCount }) {
  return {
    items: items.map(formatNotificationRow),
    nextCursor,
    unreadCount,
  };
}
