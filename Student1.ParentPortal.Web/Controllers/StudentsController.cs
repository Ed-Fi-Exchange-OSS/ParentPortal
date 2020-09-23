﻿// SPDX-License-Identifier: Apache-2.0
// Licensed to the Ed-Fi Alliance under one or more agreements.
// The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
// See the LICENSE and NOTICES files in the project root for more information.

using System.Threading.Tasks;
using System.Web.Http;
using Student1.ParentPortal.Resources.Services.Students;
using Student1.ParentPortal.Web.Security;

namespace Student1.ParentPortal.Web.Controllers
{
    [RoutePrefix("api/students")]
    public class StudentsController : ApiController
    {
        private readonly IStudentsService _studentsService;

        public StudentsController(IStudentsService studentsService)
        {
            _studentsService = studentsService;
        }

        [HttpGet, Route("{id:int}")]
        public async Task<IHttpActionResult> Get(int id)
        {

            var recipient = SecurityPrincipal.Current;

            var model = await _studentsService.GetStudentDetailAsync(id, recipient.PersonUniqueId, recipient.PersonTypeId);

            if (model == null)
                return NotFound();
            
            return Ok(model);
        }

        [HttpGet, Route("{id:int}/brief")]
        public async Task<IHttpActionResult> GetBriefModel(int id)
        {
            var model = await _studentsService.GetPersonBriefModelAsync(id);

            if (model == null)
                return NotFound();

            return Ok(model);
        }
    }
}
