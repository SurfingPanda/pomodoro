<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('pomodoro_sessions', function (Blueprint $table) {
            $table->id();
            // Supabase auth user UUID (from the verified JWT). Not a FK because
            // auth.users lives in Supabase's auth schema, not Laravel's public.
            $table->uuid('user_id')->index();
            $table->string('task')->nullable();
            $table->unsignedInteger('duration_minutes')->default(25);
            $table->timestamp('completed_at')->useCurrent();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pomodoro_sessions');
    }
};
