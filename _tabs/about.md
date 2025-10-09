---
# the default layout is 'page'
title: About
icon: fas fa-info-circle
order: 4
liquid: true
---

![banner](/assets/img/about/akash.jpg)

👋 Hello, I'm **Akash Jadhav**, a Software Engineer who helps businesses build robust web applications and backend systems. I specialize in creating efficient, reliable software solutions that solve real-world problems.

🚀 With a focus on quality and best practices, I develop software that's not only functional but also maintainable and scalable. My work includes contributing to open-source projects and sharing knowledge through practical examples and case studies.

🌐 For collaboration or any queries, feel free to reach out to me.

- Email: [akash.jadhav.cse@gmail.com](mailto:akash.jadhav.cse@gmail.com)
- Resume: [Download my latest resume here](https://gambitier-resume.netlify.app/akash_jadhav_cv.pdf)

## Skills

{% capture programming_languages %}
- Go
- C#
- TypeScript
- JavaScript
{% endcapture %}

{% capture web_frameworks %}
- Gin, Fiber (Go)
- Asp.net Core
- Express.js
- NestJS
- Fastify
{% endcapture %}

{% capture databases %}
- SQL (MySQL, PostgreSQL, MS SQL Server)
- NoSQL (MongoDB)
{% endcapture %}

{% capture development_tools %}
- Docker & Containerization
- Nginx
- Git & GitHub
- Database Design
{% endcapture %}

{% capture orm_tools %}
- GORM (Go)
- SQLC (Go)
- Entity Framework (dotnet)
- Dapper (dotnet)
- Sequelize (nodejs)
- Mongoose (nodejs)
- Prisma (nodejs)
{% endcapture %}

{% capture tools %}
- Git & GitHub
- Docker
- Database Management
- API Development
{% endcapture %}

<details>
<summary>Programming Languages</summary>

{{ programming_languages | markdownify }}
</details>

<details>
<summary>Web Frameworks</summary>

{{ web_frameworks | markdownify }}
</details>

<details>
<summary>Databases</summary>

{{ databases | markdownify }}
</details>

<details>
<summary>ORM Tools</summary>

{{ orm_tools | markdownify }}
</details>

<details>
<summary>Development Tools</summary>

{{ development_tools | markdownify }}
</details>

<details>
<summary>Tools</summary>

{{ tools | markdownify }}
</details>
