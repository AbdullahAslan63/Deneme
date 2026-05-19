import { prisma } from "../config/db.js";
import { HttpError } from "../utils/httpError.js";
import {
  assertManagerOwnsBuilding,
  assertManagerOwnsExpense,
} from "../utils/access.js";

function serializeExpense(expense) {
  return {
    ...expense,
    amount: expense.amount?.toString?.() ?? String(expense.amount),
  };
}

function monthYearRange(year, month) {
  const y = parseInt(String(year), 10);
  const m = parseInt(String(month), 10);
  if (m < 1 || m > 12) {
    throw new HttpError(400, "Ay 1-12 arasında olmalıdır.");
  }
  const start = new Date(Date.UTC(y, m - 1, 1, 0, 0, 0, 0));
  const end = new Date(Date.UTC(y, m, 0, 23, 59, 59, 999));
  return { start, end };
}

function buildListWhere(buildingId, filters) {
  const where = { buildingId };
  const { month, year, category } = filters;

  if (month && year) {
    const { start, end } = monthYearRange(year, month);
    where.date = { gte: start, lte: end };
  } else if (year) {
    const y = parseInt(String(year), 10);
    where.date = {
      gte: new Date(Date.UTC(y, 0, 1)),
      lte: new Date(Date.UTC(y, 11, 31, 23, 59, 59, 999)),
    };
  }

  if (category) {
    where.category = category;
  }

  return where;
}

export async function listExpensesByBuildingService(buildingId, managerId, filters = {}) {
  await assertManagerOwnsBuilding(buildingId, managerId);

  const expenses = await prisma.expense.findMany({
    where: buildListWhere(buildingId, filters),
    orderBy: { date: "desc" },
  });

  return expenses.map(serializeExpense);
}

export async function getExpenseSummaryService(buildingId, managerId, { month, year }) {
  const building = await assertManagerOwnsBuilding(buildingId, managerId);
  const { start, end } = monthYearRange(year, month);

  const groups = await prisma.expense.groupBy({
    by: ["category"],
    where: {
      buildingId,
      date: { gte: start, lte: end },
    },
    _sum: { amount: true },
    _count: { _all: true },
  });

  let total = 0;
  const byCategory = groups.map((g) => {
    const amount = g._sum.amount ? Number(g._sum.amount) : 0;
    total += amount;
    return {
      category: g.category,
      amount: amount.toFixed(2),
      count: g._count._all,
    };
  });

  return {
    month: parseInt(String(month), 10),
    year: parseInt(String(year), 10),
    totalAmount: total.toFixed(2),
    currency: building.currency ?? "TRY",
    byCategory,
  };
}

export async function createExpenseService(
  buildingId,
  managerId,
  { title, amount, category, date, note, receiptUrl }
) {
  await assertManagerOwnsBuilding(buildingId, managerId);

  const expense = await prisma.expense.create({
    data: {
      buildingId,
      title,
      amount,
      category,
      date: new Date(date),
      note: note ?? null,
      receiptUrl: receiptUrl ?? null,
    },
  });

  return serializeExpense(expense);
}

export async function updateExpenseService(expenseId, managerId, data) {
  await assertManagerOwnsExpense(expenseId, managerId);

  const updateData = {};
  if (data.title !== undefined) updateData.title = data.title;
  if (data.amount !== undefined) updateData.amount = data.amount;
  if (data.category !== undefined) updateData.category = data.category;
  if (data.date !== undefined) updateData.date = new Date(data.date);
  if (data.note !== undefined) updateData.note = data.note;
  if (data.receiptUrl !== undefined) updateData.receiptUrl = data.receiptUrl;

  const expense = await prisma.expense.update({
    where: { id: expenseId },
    data: updateData,
  });

  return serializeExpense(expense);
}

export async function deleteExpenseService(expenseId, managerId) {
  await assertManagerOwnsExpense(expenseId, managerId);

  await prisma.expense.delete({
    where: { id: expenseId },
  });

  return { id: expenseId };
}
