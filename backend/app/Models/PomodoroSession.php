<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PomodoroSession extends Model
{
    protected $fillable = [
        'user_id',
        'task',
        'duration_minutes',
        'completed_at',
    ];

    protected function casts(): array
    {
        return [
            'duration_minutes' => 'integer',
            'completed_at' => 'datetime',
        ];
    }
}
