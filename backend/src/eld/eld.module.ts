import { Module } from '@nestjs/common';
import { EldController } from './eld.controller';
import { EldService } from './eld.service';

@Module({
  controllers: [EldController],
  providers: [EldService],
})
export class EldModule {}