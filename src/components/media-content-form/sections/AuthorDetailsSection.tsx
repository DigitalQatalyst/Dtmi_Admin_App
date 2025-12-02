import { User as UserIcon, Mail as MailIcon, Twitter as TwitterIcon, Instagram as InstagramIcon } from 'lucide-react';
import type React from 'react';

import type { MediaFormData, ValidationErrors } from '../types';

interface AuthorDetailsSectionProps {
  formData: MediaFormData;
  errors: ValidationErrors;
  onChange: (event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => void;
}

export const AuthorDetailsSection: React.FC<AuthorDetailsSectionProps> = ({ formData, errors, onChange }) => (
  <div className="bg-white shadow-sm rounded-lg overflow-hidden">
    <div className="p-6 border-b border-gray-200">
      <h2 className="text-lg font-medium text-gray-900 flex items-center gap-2">
        <UserIcon className="w-5 h-5" /> Author Details
      </h2>
      <p className="mt-1 text-sm text-gray-500">All author details and social links</p>
    </div>
    <div className="p-6 space-y-6">
      {/* Basic Information */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700">
            Author Name <span className="text-red-500">*</span>
          </label>
          <input
            name="authorName"
            value={formData.authorName}
            onChange={onChange}
            required
            className={`mt-1 block w-full border rounded-md py-2 px-3 ${
              errors.authorName ? 'border-red-500' : 'border-gray-300'
            }`}
          />
          {errors.authorName && <p className="mt-1 text-xs text-red-600">{errors.authorName}</p>}
        </div>
        <div>
          <label className="block text-sm text-gray-700">Author Organization</label>
          <input
            name="authorOrg"
            value={formData.authorOrg}
            onChange={onChange}
            className={`mt-1 block w-full border rounded-md py-2 px-3 ${
              errors.authorOrg ? 'border-red-500' : 'border-gray-300'
            }`}
            aria-invalid={!!errors.authorOrg}
          />
          {errors.authorOrg && <p className="mt-1 text-xs text-red-600">{errors.authorOrg}</p>}
        </div>
        <div>
          <label className="block text-sm text-gray-700">Author Role/Title</label>
          <input
            name="authorTitle"
            value={formData.authorTitle}
            onChange={onChange}
            className={`mt-1 block w-full border rounded-md py-2 px-3 ${
              errors.authorTitle ? 'border-red-500' : 'border-gray-300'
            }`}
            aria-invalid={!!errors.authorTitle}
          />
          {errors.authorTitle && <p className="mt-1 text-xs text-red-600">{errors.authorTitle}</p>}
        </div>
        <div>
          <label className="block text-sm text-gray-700">Author Photo URL</label>
          <input
            name="authorPhotoUrl"
            value={formData.authorPhotoUrl}
            onChange={onChange}
            placeholder="https://example.com/photo.jpg"
            className={`mt-1 block w-full border rounded-md py-2 px-3 ${
              errors.authorPhotoUrl ? 'border-red-500' : 'border-gray-300'
            }`}
            aria-invalid={!!errors.authorPhotoUrl}
          />
          {errors.authorPhotoUrl && <p className="mt-1 text-xs text-red-600">{errors.authorPhotoUrl}</p>}
        </div>
        <div className="md:col-span-2">
          <label className="block text-sm text-gray-700">Author Bio</label>
          <textarea
            name="authorBio"
            rows={3}
            value={formData.authorBio}
            onChange={onChange}
            placeholder="Brief biography or description..."
            className={`mt-1 block w-full border rounded-md py-2 px-3 ${
              errors.authorBio ? 'border-red-500' : 'border-gray-300'
            }`}
            aria-invalid={!!errors.authorBio}
          />
          {errors.authorBio && <p className="mt-1 text-xs text-red-600">{errors.authorBio}</p>}
        </div>
      </div>

      {/* Social Media Links */}
      <div className="border-t pt-6">
        <h3 className="text-sm font-medium text-gray-900 mb-4">Social Media Links (Optional)</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label className="block text-sm text-gray-700 flex items-center gap-2">
              <MailIcon className="w-4 h-4 text-gray-500" />
              Email
            </label>
            <input
              type="email"
              name="authorEmail"
              value={formData.authorEmail}
              onChange={onChange}
              placeholder="author@example.com"
              className={`mt-1 block w-full border rounded-md py-2 px-3 ${
                errors.authorEmail ? 'border-red-500' : 'border-gray-300'
              }`}
              aria-invalid={!!errors.authorEmail}
            />
            {errors.authorEmail && <p className="mt-1 text-xs text-red-600">{errors.authorEmail}</p>}
          </div>
          <div>
            <label className="block text-sm text-gray-700 flex items-center gap-2">
              <TwitterIcon className="w-4 h-4 text-blue-400" />
              Twitter
            </label>
            <input
              type="text"
              name="authorTwitter"
              value={formData.authorTwitter}
              onChange={onChange}
              placeholder="@username or full URL"
              className={`mt-1 block w-full border rounded-md py-2 px-3 ${
                errors.authorTwitter ? 'border-red-500' : 'border-gray-300'
              }`}
              aria-invalid={!!errors.authorTwitter}
            />
            {errors.authorTwitter && <p className="mt-1 text-xs text-red-600">{errors.authorTwitter}</p>}
            <p className="mt-1 text-xs text-gray-500">e.g., @username or https://twitter.com/username</p>
          </div>
          <div>
            <label className="block text-sm text-gray-700 flex items-center gap-2">
              <InstagramIcon className="w-4 h-4 text-pink-500" />
              Instagram
            </label>
            <input
              type="text"
              name="authorInstagram"
              value={formData.authorInstagram}
              onChange={onChange}
              placeholder="@username or full URL"
              className={`mt-1 block w-full border rounded-md py-2 px-3 ${
                errors.authorInstagram ? 'border-red-500' : 'border-gray-300'
              }`}
              aria-invalid={!!errors.authorInstagram}
            />
            {errors.authorInstagram && <p className="mt-1 text-xs text-red-600">{errors.authorInstagram}</p>}
            <p className="mt-1 text-xs text-gray-500">e.g., @username or https://instagram.com/username</p>
          </div>
        </div>
      </div>
    </div>
  </div>
);

export default AuthorDetailsSection;

