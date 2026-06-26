<?php

namespace App\Http\Controllers;

use App\Models\Task;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TaskController extends Controller
{
    private function userId(Request $request): string
    {
        return $request->attributes->get('supabase_user')['id'];
    }

    /**
     * List the current user's tasks (open first, newest first).
     */
    public function index(Request $request): JsonResponse
    {
        $tasks = Task::where('user_id', $this->userId($request))
            ->orderBy('is_done')
            ->orderByDesc('created_at')
            ->get();

        return response()->json($tasks);
    }

    /**
     * Create a task for the current user.
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'title' => ['required', 'string', 'max:255'],
        ]);

        $task = Task::create([
            'user_id' => $this->userId($request),
            'title' => $data['title'],
            'is_done' => false,
        ]);

        return response()->json($task, 201);
    }

    /**
     * Update a task (toggle done and/or rename).
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $task = Task::where('user_id', $this->userId($request))->find($id);

        if (! $task) {
            return response()->json(['message' => 'Task not found.'], 404);
        }

        $data = $request->validate([
            'title' => ['sometimes', 'string', 'max:255'],
            'is_done' => ['sometimes', 'boolean'],
        ]);

        $task->update($data);

        return response()->json($task);
    }

    /**
     * Delete a task.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $deleted = Task::where('user_id', $this->userId($request))
            ->where('id', $id)
            ->delete();

        if (! $deleted) {
            return response()->json(['message' => 'Task not found.'], 404);
        }

        return response()->json(['message' => 'Deleted.']);
    }
}
