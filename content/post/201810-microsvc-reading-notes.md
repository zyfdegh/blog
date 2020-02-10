+++
title = "《微服务设计》读书笔记"
date = "2018-10-01"
+++

书名：微服务设计（Building Microservices）
作者：[英] Sam Newman 崔立强译
出版社：人民邮电出版社

## 微服务概念

**怎么的服务算“微”服务？**

没有固定的约定标准啦，“使用代码行数来衡量是有问题的”，但通常的经验是
“微服务应该在可以在两周内完全重写”，“足够小即可，不要过小”，
“如果你不再感觉你的代码库过大，可能它就足够小了”。

另外，微服务应该具备以下特性：

* 专注于做好一件事
* 小团队易于正常维护
* 可以独立地部署在 PaaS 上
* 服务之间通过网络调用进行通信
* 对单个服务修改，不会影响其他任何服务

**微服务架构的好处**

* 技术异构：便于对单个服务选择最合适的技术
* 弹性：能够处理服务不可用和功能降级问题
* 扩展性：易于水平拓展，避免单体应用因部分模块性能问题而对整个服务扩展
* 简化部署：对某个微服务实现小、轻、快的改动和发布，免除单体应用较长的发布周期
* 与小团队相配：小型代码库开发和维护高校，且易于在团队之前迁移
* 组合性：拆分后的服务与接口，还可以对特定业务场景进行重组
* 易替代性：重写和移除一个服务阻碍相对较小

**康威定律**

英文：Any organization that designs a system (defined broadly) will 
produce a design whose structure is a copy of the organization's 
communication structure.

中译：任何组织架构在设计一套系统（广义概念上的系统）时，所交付的设计方案在结构上
都与该组织的沟通结构保持一致。

—— 1968.04 Mel Convey

## 什么样是好的服务
**松耦合**
修改一个服务就不需要修改另一个服务，也不需要修改系统的其他部分。两个服务间也要
避免过度通信，否则也会导致紧耦合。

**高内聚**
相关的行为最好聚在一起，而不是很多地方。防止在需要改动时修改很多服务，发布多个
微服务也会带来更大风险。

**限界上下文**
限界上下文（bounded context），书中的两种定义和示例略微简略，没那么让人印象深刻。

Okay，这个词来自于 [DDD（Domain-driven design）][wiki-ddd]，Wikipedia 的解释是：

Multiple models are in play on any large project. Yet when code based on distinct models is combined, software becomes buggy, unreliable, and difficult to understand. Communication among team members becomes confusing. It is often unclear in what context a model should not be applied.

Therefore: Explicitly define the context within which a model applies. Explicitly set boundaries in terms of team organization, usage within specific parts of the application, and physical manifestations such as code bases and database schemas. Keep the model strictly consistent within these bounds, but don’t be distracted or confused by issues outside.

任何大型项目都有多个模型。 然而，当基于不同模型的代码相组合，软件变得越来越多，不可靠，并且难以理解。
团队成员之间的交流变得越来越难。 模型的使用情境变得越来越不清晰。

因此：需要明确定义模型适用的上下文，并且根据团队组织，应用程序特定部分的使用情况以及代码库和数据库模式等物理表现明确设置边界。 保持模型在这些范围内严格一致，并且不被外部的问题影响。

另外一篇解释的文章：[《Microservices, bounded context, cohesion. What do they have in common?》][post1]

个人的理解是：数据模型会在项目的多个地方，或者多个项目用到，维护的团队也会不同，这样，在管理模型的不同状态和生命周期时，就容易出现问题。具体举例来说，有一个订单的对象，从用户提交，到付款，到配送，到完成，再到售后，
会是不同的状态，也是由不同的（微）服务管理，这样在不同的服务中，究竟要使用订单的副本还是
直接操作订单模型，这是个不容易选择的问题，使用副本时会带来数据不一致问题，直接操作模型又会导致冲突。
如果没有约定模型的操作界限，则会带来问题。因此限界上下文就是用来解决这个问题。

[wiki-ddd]: https://en.wikipedia.org/wiki/Domain-driven_design
[post1]: https://hackernoon.com/microservices-bounded-context-cohesion-what-do-they-have-in-common-1107b70342b3