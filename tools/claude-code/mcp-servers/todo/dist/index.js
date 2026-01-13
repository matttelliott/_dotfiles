#!/usr/bin/env node
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { promises as fs } from "fs";
import path from "path";
import { fileURLToPath } from "url";
// Define todo file path using environment variable with fallback
const defaultTodoPath = path.join(path.dirname(fileURLToPath(import.meta.url)), "todos.json");
function getTodoFilePath() {
    if (process.env.TODO_FILE_PATH) {
        return path.isAbsolute(process.env.TODO_FILE_PATH)
            ? process.env.TODO_FILE_PATH
            : path.join(path.dirname(fileURLToPath(import.meta.url)), process.env.TODO_FILE_PATH);
    }
    return defaultTodoPath;
}
// Get default project name from current directory
function getDefaultProject() {
    return process.env.TODO_DEFAULT_PROJECT || path.basename(process.cwd());
}
// TodoManager class
class TodoManager {
    filePath;
    constructor(filePath) {
        this.filePath = filePath;
    }
    async loadTodos() {
        try {
            const data = await fs.readFile(this.filePath, "utf-8");
            return JSON.parse(data);
        }
        catch (error) {
            if (error instanceof Error &&
                "code" in error &&
                error.code === "ENOENT") {
                return [];
            }
            throw error;
        }
    }
    async saveTodos(todos) {
        await fs.writeFile(this.filePath, JSON.stringify(todos, null, 2));
    }
    generateId() {
        return Date.now().toString(36) + Math.random().toString(36).substr(2, 5);
    }
    async addTodo(content, activeForm, options = {}) {
        const todos = await this.loadTodos();
        const todo = {
            id: this.generateId(),
            content,
            activeForm,
            status: "pending",
            priority: options.priority,
            project: options.project || getDefaultProject(),
            assignee: options.assignee,
            createdAt: new Date().toISOString(),
        };
        todos.push(todo);
        await this.saveTodos(todos);
        return todo;
    }
    async syncTodos(todos, project) {
        const existingTodos = await this.loadTodos();
        const targetProject = project || getDefaultProject();
        // Remove existing todos for this project
        const otherTodos = existingTodos.filter((t) => t.project !== targetProject);
        // Add new todos
        const newTodos = todos.map((t, i) => ({
            id: this.generateId() + i,
            content: t.content,
            status: t.status,
            activeForm: t.activeForm,
            project: targetProject,
            createdAt: new Date().toISOString(),
            completedAt: t.status === "completed" ? new Date().toISOString() : undefined,
        }));
        await this.saveTodos([...otherTodos, ...newTodos]);
        return newTodos;
    }
    async listTodos(filters = {}) {
        const todos = await this.loadTodos();
        return todos.filter((todo) => {
            if (filters.status && todo.status !== filters.status)
                return false;
            if (filters.priority && todo.priority !== filters.priority)
                return false;
            if (filters.project && todo.project !== filters.project)
                return false;
            if (filters.assignee && todo.assignee !== filters.assignee)
                return false;
            return true;
        });
    }
    async listProjects() {
        const todos = await this.loadTodos();
        return [...new Set(todos.map((t) => t.project))];
    }
    async updateTodo(id, updates) {
        const todos = await this.loadTodos();
        const index = todos.findIndex((t) => t.id === id);
        if (index === -1) {
            throw new Error(`Todo with id ${id} not found`);
        }
        const todo = todos[index];
        if (updates.content !== undefined)
            todo.content = updates.content;
        if (updates.activeForm !== undefined)
            todo.activeForm = updates.activeForm;
        if (updates.priority !== undefined)
            todo.priority = updates.priority;
        if (updates.project !== undefined)
            todo.project = updates.project;
        if (updates.assignee !== undefined)
            todo.assignee = updates.assignee;
        if (updates.status !== undefined) {
            todo.status = updates.status;
            if (updates.status === "completed" && !todo.completedAt) {
                todo.completedAt = new Date().toISOString();
            }
            else if (updates.status !== "completed") {
                delete todo.completedAt;
            }
        }
        await this.saveTodos(todos);
        return todo;
    }
    async deleteTodo(id) {
        const todos = await this.loadTodos();
        const index = todos.findIndex((t) => t.id === id);
        if (index === -1) {
            throw new Error(`Todo with id ${id} not found`);
        }
        todos.splice(index, 1);
        await this.saveTodos(todos);
    }
    async clearCompleted(project) {
        const todos = await this.loadTodos();
        const initialLength = todos.length;
        const remaining = todos.filter((t) => {
            if (t.status !== "completed")
                return true;
            if (project && t.project !== project)
                return true;
            return false;
        });
        await this.saveTodos(remaining);
        return initialLength - remaining.length;
    }
}
// Create server
const server = new McpServer({
    name: "todo",
    version: "1.0.0",
});
const todoManager = new TodoManager(getTodoFilePath());
// Register tools
server.tool("add_todo", "Add a new todo item (compatible with Claude's TodoWrite format)", {
    content: z.string().describe("The todo description (imperative form, e.g., 'Fix the bug')"),
    activeForm: z.string().describe("Present continuous form (e.g., 'Fixing the bug')"),
    priority: z
        .enum(["low", "medium", "high"])
        .optional()
        .describe("Priority level"),
    project: z
        .string()
        .optional()
        .describe("Project name (default: current directory name)"),
    assignee: z
        .string()
        .optional()
        .describe("Assignee (agent name or context)"),
}, async ({ content, activeForm, priority, project, assignee }) => {
    const todo = await todoManager.addTodo(content, activeForm, { priority, project, assignee });
    return {
        content: [{ type: "text", text: JSON.stringify(todo, null, 2) }],
    };
});
server.tool("sync_todos", "Sync todos from Claude's built-in TodoWrite format. Replaces all todos for the project.", {
    todos: z.array(z.object({
        content: z.string(),
        status: z.enum(["pending", "in_progress", "completed"]),
        activeForm: z.string(),
    })).describe("Array of todos in Claude's format"),
    project: z.string().optional().describe("Project name (default: current directory name)"),
}, async ({ todos, project }) => {
    const synced = await todoManager.syncTodos(todos, project);
    return {
        content: [{ type: "text", text: JSON.stringify(synced, null, 2) }],
    };
});
server.tool("list_todos", "List todos, optionally filtered by status, priority, project, or assignee", {
    status: z
        .enum(["pending", "in_progress", "completed"])
        .optional()
        .describe("Filter by status"),
    priority: z
        .enum(["low", "medium", "high"])
        .optional()
        .describe("Filter by priority"),
    project: z.string().optional().describe("Filter by project"),
    assignee: z.string().optional().describe("Filter by assignee"),
}, async ({ status, priority, project, assignee }) => {
    const todos = await todoManager.listTodos({ status, priority, project, assignee });
    return {
        content: [{ type: "text", text: JSON.stringify(todos, null, 2) }],
    };
});
server.tool("list_projects", "List all projects that have todos", {}, async () => {
    const projects = await todoManager.listProjects();
    return {
        content: [{ type: "text", text: JSON.stringify(projects, null, 2) }],
    };
});
server.tool("update_todo", "Update an existing todo", {
    id: z.string().describe("The todo ID"),
    content: z.string().optional().describe("New description"),
    activeForm: z.string().optional().describe("New active form"),
    status: z
        .enum(["pending", "in_progress", "completed"])
        .optional()
        .describe("New status"),
    priority: z
        .enum(["low", "medium", "high"])
        .optional()
        .describe("New priority"),
    project: z.string().optional().describe("Move to different project"),
    assignee: z.string().optional().describe("Reassign to different agent"),
}, async ({ id, content, activeForm, status, priority, project, assignee }) => {
    const todo = await todoManager.updateTodo(id, { content, activeForm, status, priority, project, assignee });
    return {
        content: [{ type: "text", text: JSON.stringify(todo, null, 2) }],
    };
});
server.tool("delete_todo", "Delete a todo by ID", {
    id: z.string().describe("The todo ID to delete"),
}, async ({ id }) => {
    await todoManager.deleteTodo(id);
    return {
        content: [{ type: "text", text: `Deleted todo ${id}` }],
    };
});
server.tool("clear_completed", "Remove all completed todos, optionally for a specific project", {
    project: z.string().optional().describe("Only clear completed todos for this project"),
}, async ({ project }) => {
    const count = await todoManager.clearCompleted(project);
    return {
        content: [{ type: "text", text: `Cleared ${count} completed todos` }],
    };
});
// Start server
async function main() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
}
main().catch(console.error);
