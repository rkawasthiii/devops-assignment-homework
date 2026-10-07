const test = require("node:test");
const assert = require("node:assert");
const { greeting } = require("../app/server");

test("greeting returns Hello World by default", () => {
  assert.strictEqual(greeting(), "Hello World from the CI/CD demo app!");
});

test("greeting uses the provided name", () => {
  assert.strictEqual(greeting("DevOps"), "Hello DevOps from the CI/CD demo app!");
});
