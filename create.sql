create table nico_video_item(
       content_id varchar(50) primary key,
       title varchar(300),
       created_at default CURRENT_TIMESTAMP
);
create table nico_video_detail(
       content_id varchar(50),
       insert_date default CURRENT_TIMESTAMP,
       view_counter integer,
       mylist_counter integer,
       foreign key(content_id)
               references nico_video_item(content_id)
               on delete cascade, --いらないかも
       primary key(content_id,insert_date)
);
