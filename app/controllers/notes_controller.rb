class NotesController < ApplicationController
  before_action :require_login
  before_action :set_note, only: [:show, :edit, :update, :destroy]

  def index
    Rails.logger.info "Notes accessed by user: #{@current_user.name}"
    
    # Get search and sort parameters
    search = params[:search]&.strip
    sort_by = params[:sort_by] || 'created_at'
    sort_order = params[:sort_order] || 'desc'
    
    notes = Note.filtered_and_sorted(@current_user, search: search, sort_by: sort_by, sort_order: sort_order)
    
    render inertia: 'Notes/Index', props: {
      user: user_props,
      notes: notes.map { |note| note_props(note) },
      search: search,
      sort_by: sort_by,
      sort_order: sort_order
    }
  end

  def show
    render inertia: 'Notes/Show', props: {
      user: user_props,
      note: note_props(@note)
    }
  end

  def edit
    render inertia: 'Notes/Index', props: {
      user: user_props,
      notes: @current_user.notes.recent.map { |note| note_props(note) },
      editing_note: note_props(@note)
    }
  end

  def create
    @note = @current_user.notes.build(note_params)
    
    if @note.save
      render inertia: 'Notes/Index', props: {
        user: user_props,
        notes: @current_user.notes.recent.map { |note| note_props(note) },
        success_message: "Note created successfully!"
      }
    else
      render inertia: 'Notes/Index', props: {
        user: user_props,
        notes: @current_user.notes.recent.map { |note| note_props(note) },
        errors: @note.errors.full_messages,
        note: { title: note_params[:title], content: note_params[:content] }
      }
    end
  end

  def update
    if @note.update(note_params)
      render inertia: 'Notes/Index', props: {
        user: user_props,
        notes: @current_user.notes.recent.map { |note| note_props(note) },
        success_message: "Note updated successfully!"
      }
    else
      render inertia: 'Notes/Index', props: {
        user: user_props,
        notes: @current_user.notes.recent.map { |note| note_props(note) },
        errors: @note.errors.full_messages,
        editing_note: note_props(@note)
      }
    end
  end

  def destroy
    @note.destroy
    
    render inertia: 'Notes/Index', props: {
      user: user_props,
      notes: @current_user.notes.recent.map { |note| note_props(note) },
      success_message: "Note deleted successfully!"
    }
  end

  private

  def set_note
    @note = @current_user.notes.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:title, :content)
  end

  def note_props(note)
    {
      id: note.id,
      title: note.title,
      content: note.content,
      created_at: format_date(note.created_at),
      updated_at: format_date(note.updated_at)
    }
  end
end 