﻿using Student1.ParentPortal.Data.Models;
using Student1.ParentPortal.Models.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Student1.ParentPortal.Resources.Services.Admin
{
    public class AdminService : IAdminService
    {
        private readonly IAdminRepository _adminRepository;

        public AdminService(IAdminRepository adminRepository)
        {
            _adminRepository = adminRepository;
        }

        public async Task<AdminStudentDetailFeatureModel> GetStudentDetailFeatures()
        {
            return await _adminRepository.GetStudentDetailFeatures();
        }

        public async Task<bool> IsAdminUser(string email)
        {
            var isAdmin = await _adminRepository.GetAdminIdentityByEmailAsync(email);
            return isAdmin.Any();
        }

        public async Task<AdminStudentDetailFeatureModel> SaveStudentDetailFeatures(AdminStudentDetailFeatureModel model)
        {
            return await _adminRepository.SaveStudentDetailFeatures(model);
        }
    }
}
