/** @type {import('jest').Config} */
export default {
  testEnvironment: "node",
  transform: {},
  extensionsToTreatAsEsm: [".js"],
  moduleNameMapper: {
    "^(\\.{1,2}/.*)\\.js$": "$1",
  },
  testMatch: ["**/__tests__/**/*.test.js"],
  verbose: true,
  forceExit: true,
  clearMocks: true,
  resetMocks: true,
  restoreMocks: true,
  coveragePathIgnorePatterns: [
    "/node_modules/",
    "/__tests__/",
  ],
  // Test veritabanı kullanımı için
  setupFilesAfterEnv: ["./__tests__/setup.js"],
};
