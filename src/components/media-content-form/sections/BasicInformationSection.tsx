import { RefreshCcw as RefreshIcon, Type as TypeIcon, Plus as PlusIcon, X as XIcon, Lightbulb as LightbulbIcon } from 'lucide-react';
import type React from 'react';
import { useState } from 'react';

import type { MediaFormData, ValidationErrors } from '../types';

interface BasicInformationSectionProps {
  formData: MediaFormData;
  errors: ValidationErrors;
  onChange: (event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => void;
  onSlugChange: (value: string) => void;
  onSlugRegenerate: () => void;
  onInsightsChange: (insights: string[]) => void;
}

export const BasicInformationSection: React.FC<BasicInformationSectionProps> = ({
  formData,
  errors,
  onChange,
  onSlugChange,
  onSlugRegenerate,
  onInsightsChange,
}) => {
  const [newInsight, setNewInsight] = useState('');
  const [editingIndex, setEditingIndex] = useState<number | null>(null);
  const [editingText, setEditingText] = useState('');

  const insights = formData.insights || [];

  const handleAddInsight = () => {
    if (newInsight.trim()) {
      onInsightsChange([...insights, newInsight.trim()]);
      setNewInsight('');
    }
  };

  const handleRemoveInsight = (index: number) => {
    onInsightsChange(insights.filter((_, i) => i !== index));
  };

  const handleStartEdit = (index: number) => {
    setEditingIndex(index);
    setEditingText(insights[index]);
  };

  const handleSaveEdit = () => {
    if (editingIndex !== null && editingText.trim()) {
      const updatedInsights = [...insights];
      updatedInsights[editingIndex] = editingText.trim();
      onInsightsChange(updatedInsights);
      setEditingIndex(null);
      setEditingText('');
    }
  };

  const handleCancelEdit = () => {
    setEditingIndex(null);
    setEditingText('');
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      if (editingIndex !== null) {
        handleSaveEdit();
      } else {
        handleAddInsight();
      }
    } else if (e.key === 'Escape') {
      if (editingIndex !== null) {
        handleCancelEdit();
      }
    }
  };

  return (
    <div className="bg-white shadow-sm rounded-lg overflow-hidden">
      <div className="p-6 border-b border-gray-200">
        <h2 className="text-lg font-medium text-gray-900 flex items-center gap-2">
          <TypeIcon className="w-5 h-5" /> Basic Information
        </h2>
        <p className="mt-1 text-sm text-gray-500">Title, status and summary</p>
      </div>
      <div className="p-6 grid grid-cols-1 gap-y-6 sm:grid-cols-2 sm:gap-x-6">
        <div className="sm:col-span-2">
          <label htmlFor="title" className="block text-sm font-medium text-gray-700">
            Title <span className="text-red-500">*</span>
          </label>
          <input
            id="title"
            name="title"
            value={formData.title}
            onChange={onChange}
            required
            className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
          />
          {errors.title && <p className="mt-1 text-xs text-red-600">{errors.title}</p>}
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700">Slug</label>
          <input
            id="slug"
            value={formData.slug}
            onChange={(event) => onSlugChange(event.target.value)}
            className={`mt-1 block w-full border rounded-md py-2 px-3 bg-white text-gray-700 ${
              errors.slug ? 'border-red-500 focus:border-red-500 focus:ring-red-500' : 'border-gray-300'
            } focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm`}
          />
          <div className="mt-1 flex items-center justify-between">
            {errors.slug ? (
              <p className="text-xs text-red-600">{errors.slug}</p>
            ) : (
              <p className="text-xs text-gray-500">Auto-generated from title, but you can edit it.</p>
            )}
            <button
              type="button"
              onClick={onSlugRegenerate}
              className="inline-flex items-center gap-1 text-xs text-blue-600 hover:text-blue-700"
            >
              <RefreshIcon className="w-3 h-3" />
              Regenerate
            </button>
          </div>
        </div>
        <div className="sm:col-span-2">
          <label htmlFor="summary" className="block text-sm font-medium text-gray-700">
            Summary <span className="text-red-500">*</span>
          </label>
          <textarea
            id="summary"
            name="summary"
            rows={2}
            value={formData.summary}
            onChange={onChange}
            required
            className={`mt-1 block w-full border rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm ${
              errors.summary ? 'border-red-500' : 'border-gray-300'
            }`}
          />
          {errors.summary && <p className="mt-1 text-xs text-red-600">{errors.summary}</p>}
        </div>

        {/* Key Insights Section */}
        <div className="sm:col-span-2">
          <label className="block text-sm font-medium text-gray-700 mb-2 flex items-center gap-2">
            <LightbulbIcon className="w-4 h-4 text-amber-500" />
            Key Insights
          </label>
          <p className="text-xs text-gray-500 mb-3">Add key insights or takeaways in point form</p>
          
          {/* Insights List */}
          {insights.length > 0 && (
            <div className="mb-3 space-y-2">
              {insights.map((insight, index) => (
                <div
                  key={index}
                  className="flex items-start gap-2 p-3 bg-blue-50 border border-blue-100 rounded-md group hover:bg-blue-100 transition-colors"
                >
                  <div className="flex-shrink-0 mt-0.5">
                    <div className="w-5 h-5 rounded-full bg-blue-500 text-white flex items-center justify-center text-xs font-medium">
                      {index + 1}
                    </div>
                  </div>
                  {editingIndex === index ? (
                    <div className="flex-1 flex items-center gap-2">
                      <input
                        type="text"
                        value={editingText}
                        onChange={(e) => setEditingText(e.target.value)}
                        onKeyDown={handleKeyDown}
                        className="flex-1 px-2 py-1 text-sm border border-blue-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                        autoFocus
                      />
                      <button
                        type="button"
                        onClick={handleSaveEdit}
                        className="px-2 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700"
                      >
                        Save
                      </button>
                      <button
                        type="button"
                        onClick={handleCancelEdit}
                        className="px-2 py-1 text-xs bg-gray-300 text-gray-700 rounded hover:bg-gray-400"
                      >
                        Cancel
                      </button>
                    </div>
                  ) : (
                    <>
                      <p className="flex-1 text-sm text-gray-700">{insight}</p>
                      <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button
                          type="button"
                          onClick={() => handleStartEdit(index)}
                          className="p-1 text-blue-600 hover:text-blue-700 hover:bg-blue-200 rounded"
                          title="Edit insight"
                        >
                          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                          </svg>
                        </button>
                        <button
                          type="button"
                          onClick={() => handleRemoveInsight(index)}
                          className="p-1 text-red-600 hover:text-red-700 hover:bg-red-100 rounded"
                          title="Remove insight"
                        >
                          <XIcon className="w-4 h-4" />
                        </button>
                      </div>
                    </>
                  )}
                </div>
              ))}
            </div>
          )}

          {/* Add New Insight */}
          <div className="flex gap-2">
            <input
              type="text"
              value={newInsight}
              onChange={(e) => setNewInsight(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="Enter a key insight..."
              className="flex-1 px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
            <button
              type="button"
              onClick={handleAddInsight}
              disabled={!newInsight.trim()}
              className="inline-flex items-center gap-1 px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <PlusIcon className="w-4 h-4" />
              Add
            </button>
          </div>
          <p className="mt-2 text-xs text-gray-500">
            Press Enter to add, or click the Add button
          </p>
        </div>
      </div>
    </div>
  );
};

export default BasicInformationSection;

