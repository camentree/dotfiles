# Restrict the organization users endpoint to the caller's facilities

Task: https://linear.app/august-health/issue/INT-569
Branch: camen/int-569-api-integrations-update-get-organization-users-endpoint-to

The public endpoint that lists an organization's users returns everyone, even when the caller only has read access to one facility. Return only the users the caller's facility grants cover.

## Acceptance Criteria

- An org-scoped caller sees every user in the organization
- A caller scoped to facility 10 sees users with FacilityStaff at facility 10
- A caller scoped to facility 10 sees users with org-wide FacilityStaff
- A caller scoped to facilities 10 and 11 sees the union
- A caller scoped to facility 10 does not see users only at facility 11
- A visible user's assignments at facilities the caller cannot see are not in the response
- Users whose only group type is org admin are still returned
- A caller with no facility grants gets an empty list, not an error
- Pagination counts reflect the filtered set
- No change to the request or response schema

## Files

- loquat/app/controllers/OrganizationUsersController.scala
- loquat/app/services/UserDirectoryService.scala
- loquat/test/controllers/OrganizationUsersControllerSpec.scala

## Groups

- query-filter: criteria 1–5, 8 — `done <sha>` once built
- strip-hidden-assignments: criteria 6, 7
- pagination: criteria 9, 10

## Decisions

- Filter in the query, not in memory. The endpoint paginates, and an in-memory filter would break the counts.
- Strip assignments at facilities the caller cannot see. Alternative: return them. Rejected because it leaks what the task is hiding. Asked Camen.
- Keep returning org admins. Alternative: FacilityStaff only, as the ticket literally says. Rejected because partners attribute incidents to admins today. Asked Camen.
- Reused the facility-scope predicate from the incidents query rather than writing a second one. Added during build.

## Out of scope

- The org-scoped path. Unchanged.
- The response schema.
- A partner changelog entry. Separate task.
