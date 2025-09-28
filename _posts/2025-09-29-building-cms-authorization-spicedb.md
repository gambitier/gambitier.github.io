---
title: "Building Collaborative Content Management with SpiceDB: A Real-World Authorization Journey"
date: 2025-09-28
categories: [Authorization, Content Management]
tags: [SpiceDB, Authorization, Content Management, Fine-grained Access Control, Go, Microservices]
author: gambitier
pin: false
mermaid: true
---

In today's collaborative work environments, managing content access across organizations, teams, and individual profiles requires sophisticated authorization systems. Traditional role-based access control (RBAC) often falls short when dealing with complex, hierarchical relationships and dynamic permissions.

This blog post explores how we built a robust collaborative content management system using [SpiceDB](https://authzed.com/), Authzed's open-source authorization database. We'll dive into real-world patterns for modeling organizations, teams, profiles, and content visibility without compromising security or performance.

## The Challenge: Complex Authorization Requirements

Modern content management systems need to handle intricate authorization scenarios:

- **Organizational Hierarchies**: Multiple organizations with their own content and users
- **Team-Based Access**: Teams within organizations that can collaborate on content
- **Profile Management**: Individual profiles with specific permissions and privacy controls
- **Content Visibility**: Granular control over who can view, edit, or manage content
- **Dynamic Permissions**: Real-time permission changes without system restarts

Traditional approaches often lead to complex, hard-to-maintain authorization logic scattered across the application. SpiceDB provides a centralized, schema-driven solution that scales with your authorization complexity.

## SpiceDB: The Foundation

SpiceDB is a Zanzibar-inspired authorization database that provides:

- **Consistent Authorization**: Global consistency guarantees for permission checks
- **Schema-Driven**: Define your authorization model in a declarative schema
- **High Performance**: Sub-millisecond permission checks at scale
- **Real-time Updates**: Immediate permission changes across all services

## Our Content Management Schema

Let's explore how we modeled our collaborative content management system:

```zed
definition user {
    relation member_of: organization
    relation profile: profile
}

definition organization {
    relation member: user
    relation team: team
    relation content: content
}

definition team {
    relation member: user
    relation manager: user
    relation organization: organization
    relation content: content
}

definition profile {
    relation owner: user
    relation manager: user
    relation organization: organization
}

definition content {
    relation owner: user
    relation organization: organization
    relation team: team
    relation visibility: visibility_object
    
    permission view = owner + organization->member + team->member + visibility->viewer
    permission edit = owner + organization->member + team->member + visibility->editor
    permission manage = owner + organization->member + team->manager + visibility->manager
}

definition visibility_object {
    relation viewer: user
    relation editor: user
    relation manager: user
    relation public_viewer: user
    relation public_subscriber: user
}
```

## Key Authorization Patterns

### 1. Organizational Access Control

Organizations serve as the top-level container for content and users:

```go
// Grant organization membership
func (s *AuthorizationService) AddUserToOrganization(ctx context.Context, userID, orgID string) error {
    return s.WriteRelationship(ctx, &v1.Relationship{
        Resource: &v1.ObjectReference{
            ObjectType: "organization",
            ObjectId:   orgID,
        },
        Relation: "member",
        Subject: &v1.SubjectReference{
            Object: &v1.ObjectReference{
                ObjectType: "user",
                ObjectId:   userID,
            },
        },
    })
}
```

### 2. Team-Based Collaboration

Teams within organizations can collaborate on content:

```go
// Create team and assign members
func (s *AuthorizationService) CreateTeam(ctx context.Context, teamID, orgID string, members []string) error {
    // Create team-organization relationship
    if err := s.WriteRelationship(ctx, &v1.Relationship{
        Resource: &v1.ObjectReference{
            ObjectType: "team",
            ObjectId:   teamID,
        },
        Relation: "organization",
        Subject: &v1.SubjectReference{
            Object: &v1.ObjectReference{
                ObjectType: "organization",
                ObjectId:   orgID,
            },
        },
    }); err != nil {
        return err
    }

    // Add team members
    for _, memberID := range members {
        if err := s.WriteRelationship(ctx, &v1.Relationship{
            Resource: &v1.ObjectReference{
                ObjectType: "team",
                ObjectId:   teamID,
            },
            Relation: "member",
            Subject: &v1.SubjectReference{
                Object: &v1.ObjectReference{
                    ObjectType: "user",
                    ObjectId:   memberID,
                },
            },
        }); err != nil {
            return err
        }
    }
    return nil
}
```

### 3. Profile Privacy Management

Profiles can have managers without exposing sensitive information:

```go
// Assign profile manager without sharing profile data
func (s *AuthorizationService) AssignProfileManager(ctx context.Context, profileID, managerID string) error {
    return s.WriteRelationship(ctx, &v1.Relationship{
        Resource: &v1.ObjectReference{
            ObjectType: "profile",
            ObjectId:   profileID,
        },
        Relation: "manager",
        Subject: &v1.SubjectReference{
            Object: &v1.ObjectReference{
                ObjectType: "user",
                ObjectId:   managerID,
            },
        },
    })
}
```

### 4. Content Visibility Control

Our system supports multiple visibility levels:

```go
type VisibilityType string

const (
    VisibilityPublic    VisibilityType = "public"
    VisibilityPrivate   VisibilityType = "private"
    VisibilityTeam      VisibilityType = "team"
    VisibilityHidden    VisibilityType = "hidden"
)

func (s *AuthorizationService) SetContentVisibility(ctx context.Context, contentID string, visibility VisibilityType) error {
    // Remove existing visibility relationships
    if err := s.removeAllVisibilityRelationships(ctx, contentID); err != nil {
        return fmt.Errorf("failed to remove existing visibility: %w", err)
    }

    // Set new visibility based on type
    switch visibility {
    case VisibilityPublic:
        return s.setPublicVisibility(ctx, contentID)
    case VisibilityPrivate:
        return s.setPrivateVisibility(ctx, contentID)
    case VisibilityTeam:
        return s.setTeamVisibility(ctx, contentID)
    case VisibilityHidden:
        return s.setHiddenVisibility(ctx, contentID)
    default:
        return fmt.Errorf("unsupported visibility type: %s", visibility)
    }
}
```

## Migration Strategy: Zero-Downtime Updates

One of the biggest challenges in authorization systems is migrating existing permissions without downtime. We implemented a comprehensive migration strategy:

### 1. Schema Evolution

SpiceDB supports schema evolution, allowing us to add new relationship types without breaking existing functionality:

```go
// Migration service for updating visibility relationships
func (s *MigrationService) MigrateContentVisibility(ctx context.Context) error {
    // Get all content items
    contents, err := s.fetchAllContent(ctx)
    if err != nil {
        return fmt.Errorf("failed to fetch content: %w", err)
    }

    for _, content := range contents {
        // Migrate each content item to new visibility system
        if err := s.migrateContentVisibility(ctx, content); err != nil {
            log.Printf("Failed to migrate content %s: %v", content.ID, err)
            continue
        }
    }
    return nil
}
```

### 2. Idempotent Migrations

Our migration system ensures operations can be safely retried:

```go
func (s *MigrationService) isMigrationCompleted(ctx context.Context, migrationID string) (bool, error) {
    collection := s.mongoClient.Database(s.db.DBName).Collection("migrations")
    
    filter := bson.M{
        "migrationId": migrationID,
        "status":      "completed",
    }
    
    count, err := collection.CountDocuments(ctx, filter)
    return count > 0, err
}
```

## Performance Optimization

### 1. Batch Operations

SpiceDB supports batch operations for better performance:

```go
func (s *AuthorizationService) BatchWriteRelationships(ctx context.Context, relationships []*v1.Relationship) error {
    request := &v1.WriteRelationshipsRequest{
        Updates: make([]*v1.RelationshipUpdate, len(relationships)),
    }
    
    for i, rel := range relationships {
        request.Updates[i] = &v1.RelationshipUpdate{
            Operation:    v1.RelationshipUpdate_OPERATION_CREATE,
            Relationship: rel,
        }
    }
    
    _, err := s.client.WriteRelationships(ctx, request)
    return err
}
```

### 2. Caching Strategy

We implemented a multi-layer caching strategy:

```go
type CachedAuthorizationService struct {
    authzService *AuthorizationService
    cache       cache.Cache
    ttl         time.Duration
}

func (c *CachedAuthorizationService) CheckPermission(ctx context.Context, params ResourcePermission) (bool, error) {
    // Generate cache key
    cacheKey := fmt.Sprintf("perm:%s:%s:%s:%s", 
        params.Resource.Type, params.Resource.ID, 
        params.Subject.Type, params.Subject.ID)
    
    // Check cache first
    if cached, found := c.cache.Get(cacheKey); found {
        return cached.(bool), nil
    }
    
    // Check permission in SpiceDB
    result, err := c.authzService.CheckPermission(ctx, params)
    if err != nil {
        return false, err
    }
    
    // Cache the result
    c.cache.Set(cacheKey, result, c.ttl)
    return result, nil
}
```

## Real-World Benefits

### 1. Simplified Permission Logic

Before SpiceDB, our permission checks were scattered across multiple services:

```go
// Old approach - complex, error-prone
func (s *ContentService) CanUserViewContent(userID, contentID string) (bool, error) {
    // Check if user owns content
    if s.isOwner(userID, contentID) {
        return true, nil
    }
    
    // Check organization membership
    if s.isOrgMember(userID, contentID) {
        return true, nil
    }
    
    // Check team membership
    if s.isTeamMember(userID, contentID) {
        return true, nil
    }
    
    // Check public visibility
    if s.isPublicContent(contentID) {
        return true, nil
    }
    
    return false, nil
}
```

With SpiceDB, permission checks become declarative:

```go
// New approach - simple, consistent
func (s *ContentService) CanUserViewContent(userID, contentID string) (bool, error) {
    return s.authzService.CheckPermission(ctx, ResourcePermission{
        Resource: Resource{
            Type: "content",
            ID:   contentID,
        },
        Permission: "view",
        Subject: Subject{
            Type: "user",
            ID:   userID,
        },
    })
}
```

### 2. Real-time Permission Updates

Permissions update immediately across all services:

```go
func (s *AuthorizationService) UpdateContentVisibility(ctx context.Context, contentID string, visibility VisibilityType) error {
    // Update visibility in SpiceDB
    if err := s.SetContentVisibility(ctx, contentID, visibility); err != nil {
        return err
    }
    
    // Permissions are immediately available to all services
    // No cache invalidation needed
    // No service restarts required
    
    return nil
}
```

## Monitoring and Observability

### 1. Permission Check Metrics

We track permission check performance and patterns:

```go
func (s *AuthorizationService) CheckPermissionWithMetrics(ctx context.Context, params ResourcePermission) (bool, error) {
    start := time.Now()
    defer func() {
        duration := time.Since(start)
        s.metrics.RecordPermissionCheck(params.Resource.Type, params.Permission, duration)
    }()
    
    return s.CheckPermission(ctx, params)
}
```

### 2. Migration Monitoring

Track migration progress and handle failures:

```go
func (s *MigrationService) RunMigrationWithMonitoring(ctx context.Context, migrationID string) error {
    // Record migration start
    s.recordMigrationStart(ctx, migrationID)
    
    defer func() {
        if r := recover(); r != nil {
            s.recordMigrationFailure(ctx, migrationID, fmt.Errorf("panic: %v", r))
        }
    }()
    
    // Run migration
    if err := s.runMigration(ctx); err != nil {
        s.recordMigrationFailure(ctx, migrationID, err)
        return err
    }
    
    // Record success
    s.recordMigrationCompletion(ctx, migrationID)
    return nil
}
```

## Lessons Learned

### 1. Schema Design is Critical

SpiceDB's schema is the foundation of your authorization system. Invest time in designing it correctly:

- **Start Simple**: Begin with basic relationships and add complexity gradually
- **Think in Terms of Permissions**: Design your schema around the permissions you need to check
- **Plan for Evolution**: Design your schema to support future requirements

### 2. Migration Strategy Matters

Authorization systems are critical infrastructure. Plan your migrations carefully:

- **Test Thoroughly**: Test migrations in staging environments that mirror production
- **Rollback Plans**: Always have a rollback strategy
- **Idempotent Operations**: Ensure migrations can be safely retried

### 3. Performance Considerations

While SpiceDB is fast, consider these optimizations:

- **Batch Operations**: Use batch APIs for bulk operations
- **Caching**: Implement appropriate caching strategies
- **Monitoring**: Monitor permission check performance and patterns

## Conclusion

Building a collaborative content management system with SpiceDB has transformed how we handle authorization. The centralized, schema-driven approach has simplified our codebase, improved performance, and made our system more maintainable.

Key takeaways:

- **Centralized Authorization**: SpiceDB provides a single source of truth for all authorization decisions
- **Schema-Driven**: Declarative authorization models are easier to understand and maintain
- **Real-time Updates**: Permission changes take effect immediately across all services
- **Scalable**: SpiceDB handles high-throughput permission checks with consistent performance

The patterns we've implemented—organizational hierarchies, team-based access, profile privacy, and content visibility—provide a solid foundation for complex authorization requirements. With proper schema design, migration strategies, and performance optimization, SpiceDB can power sophisticated authorization systems at scale.

---

## References

- [SpiceDB Documentation](https://docs.authzed.com/)
- [Zanzibar Paper](https://research.google/pubs/pub48190/)
- [SpiceDB GitHub Repository](https://github.com/authzed/spicedb)
- [Awesome SpiceDB](https://github.com/authzed/awesome-spicedb)
