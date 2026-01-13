#!/usr/bin/env node

// Hook script to sync Claude's TodoWrite calls to .claude/todos.json
// This runs as a PostToolUse hook on TodoWrite

const fs = require('fs');
const path = require('path');

const input = process.env.CLAUDE_TOOL_INPUT;
if (!input) process.exit(0);

try {
  const parsed = JSON.parse(input);
  const todos = parsed.todos;
  if (!Array.isArray(todos)) process.exit(0);

  const todoFile = path.join(process.cwd(), '.claude', 'todos.json');
  const project = path.basename(process.cwd());

  // Load existing todos from other projects
  let existingTodos = [];
  try {
    existingTodos = JSON.parse(fs.readFileSync(todoFile, 'utf-8'));
  } catch (e) {
    // File doesn't exist yet
  }

  // Keep todos from other projects
  const otherProjectTodos = existingTodos.filter(t => t.project !== project);

  // Transform Claude's todos to our format
  const newTodos = todos.map((t, i) => ({
    id: Date.now().toString(36) + Math.random().toString(36).substr(2, 5) + i,
    content: t.content,
    status: t.status,
    activeForm: t.activeForm,
    project: project,
    createdAt: new Date().toISOString(),
    completedAt: t.status === 'completed' ? new Date().toISOString() : undefined,
  }));

  // Ensure .claude directory exists
  const claudeDir = path.join(process.cwd(), '.claude');
  if (!fs.existsSync(claudeDir)) {
    fs.mkdirSync(claudeDir, { recursive: true });
  }

  // Write combined todos
  fs.writeFileSync(todoFile, JSON.stringify([...otherProjectTodos, ...newTodos], null, 2));

} catch (e) {
  // Silently fail - don't break Claude's workflow
  process.exit(0);
}
